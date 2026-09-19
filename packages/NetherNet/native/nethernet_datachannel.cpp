/** Partially auto-generated file */
#include "nethernet_datachannel.h"

#include <rtc/rtc.h>

#include <thread>
#include <mutex>
#include <condition_variable>
#include <deque>
#include <vector>
#include <atomic>
#include <string>
#include <cstring>
#include <cstdlib>
#include <stdio.h>
#include <ctime>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/ecdsa.h>
#include <openssl/ec.h>

struct Peer {
    int id = -1;
    nethernet_datachannel_callbacks callbacks{};
    std::string local_description;
    volatile long description_ready = 0;
    volatile long gathering_complete = 0;
};

struct OutgoingMessage {
    int channel;
    std::vector<char> data;
};

static std::mutex outgoing_mutex;
static std::condition_variable outgoing_condition;
static std::deque<OutgoingMessage> outgoing_messages;
static std::atomic<bool> outgoing_worker_started = false;

static void outgoing_worker() {
    for (;;) {
        OutgoingMessage message;
        {
            std::unique_lock lock(outgoing_mutex);
            outgoing_condition.wait(lock, [] { return !outgoing_messages.empty(); });
            message = std::move(outgoing_messages.front());
            outgoing_messages.pop_front();
        }

        rtcSendMessage(message.channel, message.data.data(), static_cast<int>(message.data.size()));
    }
}

static void start_outgoing_worker() {
    if (outgoing_worker_started.exchange(true)) return;
    std::thread(outgoing_worker).detach();
}

static void RTC_API rtc_log(rtcLogLevel level, const char *message) {
    (void)level;
    (void)message;
}

static constexpr unsigned char RAKNET_MAGIC[] = { 0x00, 0xff, 0xff, 0x00, 0xfe, 0xfe, 0xfe, 0xfe,
    0xfd, 0xfd, 0xfd, 0xfd, 0x12, 0x34, 0x56, 0x78 };
static constexpr char RAKNET_SERVER_NAME[] = "MCPE;Harbor;685;1.26.0;0;20;5206533088969117253;Harbor;Survival;1;19132;19133;";

static void raknet_discovery(SOCKET socket) {
    unsigned char ping[2048];
    unsigned char pong[2048];
    while (true) {
        sockaddr_in remote{};
        int remote_size = sizeof(remote);
        const int size = recvfrom(socket, reinterpret_cast<char *>(ping), sizeof(ping), 0,
            reinterpret_cast<sockaddr *>(&remote), &remote_size);
        if (size < 33 || (ping[0] != 0x01 && ping[0] != 0x02) ||
            std::memcmp(ping + 9, RAKNET_MAGIC, sizeof(RAKNET_MAGIC)) != 0)
            continue;

        int at = 0;
        pong[at++] = 0x1c;
        std::memcpy(pong + at, ping + 1, 8); at += 8;
        const uint64_t guid = 0x484152424f524e45ULL;
        for (int shift = 56; shift >= 0; shift -= 8) pong[at++] = static_cast<unsigned char>(guid >> shift);
        std::memcpy(pong + at, RAKNET_MAGIC, sizeof(RAKNET_MAGIC)); at += sizeof(RAKNET_MAGIC);
        const uint16_t name_size = static_cast<uint16_t>(sizeof(RAKNET_SERVER_NAME) - 1);
        pong[at++] = static_cast<unsigned char>(name_size >> 8);
        pong[at++] = static_cast<unsigned char>(name_size);
        std::memcpy(pong + at, RAKNET_SERVER_NAME, name_size); at += name_size;
        sendto(socket, reinterpret_cast<const char *>(pong), at, 0, reinterpret_cast<sockaddr *>(&remote), remote_size);
    }
}

static EVP_PKEY *identity_key = nullptr;

static bool load_identity_key(const char *path) {
    BIO *input = BIO_new_file(path, "rb");
    if (input) {
        identity_key = PEM_read_bio_PrivateKey(input, nullptr, nullptr, nullptr);
        BIO_free(input);
    }
    if (identity_key) return true;
    EVP_PKEY_CTX *generator = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, nullptr);
    if (!generator || EVP_PKEY_keygen_init(generator) != 1 || EVP_PKEY_CTX_set_ec_paramgen_curve_nid(generator, NID_secp384r1) != 1 || EVP_PKEY_keygen(generator, &identity_key) != 1) {
        if (generator) EVP_PKEY_CTX_free(generator);
        return false;
    }
    EVP_PKEY_CTX_free(generator);
    BIO *output = BIO_new_file(path, "wb");
    if (!output) return false;
    const bool written = PEM_write_bio_PrivateKey(output, identity_key, nullptr, nullptr, 0, nullptr, nullptr) == 1;
    BIO_free(output);
    return written;
}

static std::string base64_url(const unsigned char *data, int size) {
    std::string result(static_cast<size_t>(4 * ((size + 2) / 3)), '\0');
    const int length = EVP_EncodeBlock(reinterpret_cast<unsigned char *>(result.data()), data, size);
    result.resize(static_cast<size_t>(length));
    for (char &value : result) {
        if (value == '+') value = '-';
        if (value == '/') value = '_';
    }
    while (!result.empty() && result.back() == '=') result.pop_back();
    return result;
}

static std::string base64_standard(const unsigned char *data, int size) {
    std::string result(static_cast<size_t>(4 * ((size + 2) / 3)), '\0');
    const int length = EVP_EncodeBlock(reinterpret_cast<unsigned char *>(result.data()), data, size);
    result.resize(static_cast<size_t>(length));
    return result;
}

static bool sign_es384(const std::string &input, std::string &encoded) {
    EVP_MD_CTX *context = EVP_MD_CTX_new();
    if (!context) return false;
    bool success = false;
    if (EVP_DigestSignInit(context, nullptr, EVP_sha384(), nullptr, identity_key) == 1 &&
        EVP_DigestSignUpdate(context, input.data(), input.size()) == 1) {
        size_t size = 0;
        if (EVP_DigestSignFinal(context, nullptr, &size) == 1) {
            std::string der(size, '\0');
            if (EVP_DigestSignFinal(context, reinterpret_cast<unsigned char *>(der.data()), &size) == 1) {
                const unsigned char *cursor = reinterpret_cast<const unsigned char *>(der.data());
                ECDSA_SIG *signature = d2i_ECDSA_SIG(nullptr, &cursor, static_cast<long>(size));
                if (signature) {
                    unsigned char raw[96]{};
                    const BIGNUM *r = nullptr;
                    const BIGNUM *s = nullptr;
                    ECDSA_SIG_get0(signature, &r, &s);
                    if (BN_bn2binpad(r, raw, 48) == 48 && BN_bn2binpad(s, raw + 48, 48) == 48) {
                        encoded = base64_url(raw, sizeof(raw));
                        success = true;
                    }
                    ECDSA_SIG_free(signature);
                }
            }
        }
    }
    EVP_MD_CTX_free(context);
    return success;
}

static bool add_identity(const char *sdp, int size, char *buffer, int capacity, int &result) {
    std::string text(sdp, static_cast<size_t>(size));
    std::string fingerprints;
    size_t position = 0;
    while (position < text.size()) {
        const size_t end = text.find('\n', position);
        const size_t line_end = end == std::string::npos ? text.size() : end;
        std::string line = text.substr(position, line_end - position);
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.rfind("a=fingerprint:", 0) == 0) {
            const std::string value = line.substr(14);
            const size_t separator = value.find(' ');
            if (separator == std::string::npos) return false;
            if (!fingerprints.empty()) fingerprints += ',';
            fingerprints += "{\"algorithm\":\"" + value.substr(0, separator) + "\",\"digest\":\"" + value.substr(separator + 1) + "\"}";
        }
        position = end == std::string::npos ? text.size() : end + 1;
    }
    if (fingerprints.empty() || !identity_key) {
        std::fprintf(stderr, "[NetherNet Identity] missing fingerprint or operator key\n");
        return false;
    }
    const std::string payload = "{\"fingerprint\":[" + fingerprints + "]}";
    const std::string fingerprint_header_json = "{\"alg\":\"ES384\"}";
    const std::string fingerprint_header = base64_url(reinterpret_cast<const unsigned char *>(fingerprint_header_json.data()), static_cast<int>(fingerprint_header_json.size()));
    std::string fingerprint_signature;
    if (!sign_es384(fingerprint_header + "." + base64_url(reinterpret_cast<const unsigned char *>(payload.data()), static_cast<int>(payload.size())), fingerprint_signature)) {
        std::fprintf(stderr, "[NetherNet Identity] fingerprint signing failed\n");
        return false;
    }
    const std::string public_key = [&] {
        int length = i2d_PUBKEY(identity_key, nullptr);
        if (length <= 0) return std::string();
        std::string der(static_cast<size_t>(length), '\0');
        unsigned char *cursor = reinterpret_cast<unsigned char *>(der.data());
        i2d_PUBKEY(identity_key, &cursor);
        return base64_standard(reinterpret_cast<const unsigned char *>(der.data()), length);
    }();
    const long now = static_cast<long>(time(nullptr));
    const std::string token_header_json = "{\"alg\":\"ES384\",\"x5u\":\"" + public_key + "\"}";
    const std::string token_payload_json = "{\"exp\":" + std::to_string(now + 3600) + ",\"iat\":" + std::to_string(now) + ",\"cpk\":\"" + public_key + "\"}";
    const std::string token_header = base64_url(reinterpret_cast<const unsigned char *>(token_header_json.data()), static_cast<int>(token_header_json.size()));
    const std::string token_payload = base64_url(reinterpret_cast<const unsigned char *>(token_payload_json.data()), static_cast<int>(token_payload_json.size()));
    std::string token_signature;
    if (!sign_es384(token_header + "." + token_payload, token_signature)) {
        std::fprintf(stderr, "[NetherNet Identity] token signing failed\n");
        return false;
    }
    if (public_key.empty()) {
        std::fprintf(stderr, "[NetherNet Identity] public key encoding failed\n");
        return false;
    }
    const std::string token = token_header + "." + token_payload + "." + token_signature;
    const std::string assertion = "{\"fingerprints\":\"" + fingerprint_header + ".." + fingerprint_signature + "\",\"token\":\"" + token + "\"}";
    std::string escaped;
    escaped.reserve(assertion.size() + 32);
    for (const char value : assertion) {
        if (value == '\\' || value == '"') escaped.push_back('\\');
        escaped.push_back(value);
    }
    const std::string envelope = "{\"assertion\":\"" + escaped + "\",\"idp\":{\"domain\":\"self\",\"protocol\":\"default\"}}";
    const std::string identity = base64_standard(reinterpret_cast<const unsigned char *>(envelope.data()), static_cast<int>(envelope.size()));
    const size_t media = text.find("m=");
    if (media == std::string::npos) {
        std::fprintf(stderr, "[NetherNet Identity] answer has no media section\n");
        return false;
    }
    const size_t line_start = media == 0 || text[media - 1] == '\n' ? media : text.rfind('\n', media) + 1;
    const std::string output = text.substr(0, line_start) + "a=identity:" + identity + "\r\n" + text.substr(line_start);
    if (static_cast<int>(output.size()) > capacity) {
        std::fprintf(stderr, "[NetherNet Identity] signed answer is too large\n");
        return false;
    }
    std::memcpy(buffer, output.data(), output.size());
    result = static_cast<int>(output.size());
    return true;
}

static void plaintext_connection(SOCKET client, nethernet_answer_fn answer, void *user_data) {
    char request[65536]{};
    int received = 0;
    int body_offset = -1;
    int body_length = 0;
    while (received < static_cast<int>(sizeof(request) - 1)) {
        const int count = recv(client, request + received, sizeof(request) - 1 - received, 0);
        if (count <= 0) break;
        received += count;
        request[received] = 0;
        const char *header_end = std::strstr(request, "\r\n\r\n");
        if (!header_end) continue;
        body_offset = static_cast<int>(header_end - request) + 4;
        const char *length_header = std::strstr(request, "Content-Length:");
        body_length = length_header ? std::atoi(length_header + 15) : 0;
        if (body_length <= received - body_offset) break;
    }
    std::string path;
    const int method_size = std::strncmp(request, "GET ", 4) == 0 ? 4 : (std::strncmp(request, "POST ", 5) == 0 ? 5 : 0);
    if (method_size != 0) {
        const char *start = request + method_size;
        const char *end = std::strchr(start, ' ');
        if (end) path.assign(start, end);
    }
    if (path == "/v1/join") {
        const char response[] = "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        send(client, response, sizeof(response) - 1, 0);
    } else if (path.rfind("/v1/join/", 0) == 0 && body_offset >= 0 && body_length > 0 && body_length <= received - body_offset) {
        char answer_buffer[65536]{};
        const int answer_length = answer(request + body_offset, body_length, answer_buffer, sizeof(answer_buffer), user_data);
        char signed_answer[65536]{};
        int signed_length = 0;
        if (answer_length > 0 && add_identity(answer_buffer, answer_length, signed_answer, sizeof(signed_answer), signed_length)) {
            char header[256];
            const int header_length = std::snprintf(header, sizeof(header), "HTTP/1.1 200 OK\r\nContent-Type: application/sdp\r\nContent-Length: %d\r\nConnection: close\r\n\r\n", signed_length);
            send(client, header, header_length, 0);
            send(client, signed_answer, signed_length, 0);
        }
    } else {
        const char response[] = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        send(client, response, sizeof(response) - 1, 0);
    }
    closesocket(client);
}

static void https_connection(SOCKET client, SSL_CTX *context, nethernet_answer_fn answer, void *user_data) {
    char first_byte = 0;
    if (recv(client, &first_byte, 1, MSG_PEEK) == 1 && first_byte != 0x16) {
        plaintext_connection(client, answer, user_data);
        return;
    }
    SSL *ssl = SSL_new(context);
    if (!ssl) { closesocket(client); return; }
    SSL_set_fd(ssl, static_cast<int>(client));
    const int handshake = SSL_accept(ssl);
    if (handshake != 1) { SSL_free(ssl); closesocket(client); return; }
    char request[65536]{};
    int received = 0;
    int body_offset = -1;
    int body_length = 0;
    while (received < static_cast<int>(sizeof(request) - 1)) {
        const int count = SSL_read(ssl, request + received, static_cast<int>(sizeof(request) - 1) - received);
        if (count <= 0) break;
        received += count;
        request[received] = 0;
        const char *header_end = std::strstr(request, "\r\n\r\n");
        if (!header_end) continue;
        body_offset = static_cast<int>(header_end - request) + 4;
        const char *length_header = std::strstr(request, "Content-Length:");
        body_length = length_header ? std::atoi(length_header + 15) : 0;
        if (body_length <= received - body_offset) break;
    }
    if (received <= 0 || body_offset < 0) {
        SSL_shutdown(ssl); SSL_free(ssl); closesocket(client); return;
    }
    const char *body = request + body_offset;
    std::string path;
    if (std::strncmp(request, "GET ", 4) == 0) {
        const char *start = request + 4;
        const char *end = std::strchr(start, ' ');
        if (end) path.assign(start, end);
    } else if (std::strncmp(request, "POST ", 5) == 0) {
        const char *start = request + 5;
        const char *end = std::strchr(start, ' ');
        if (end) path.assign(start, end);
    }
    if (path == "/v1/join") {
        const char response[] = "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        SSL_write(ssl, response, sizeof(response) - 1);
    } else if (path.rfind("/v1/join/", 0) == 0 && body_length > 0 && body_length <= received - body_offset) {
        char answer_buffer[65536]{};
        const int answer_length = answer(body, body_length, answer_buffer, sizeof(answer_buffer), user_data);
        char signed_answer[65536]{};
        int signed_length = 0;
        if (answer_length > 0 && add_identity(answer_buffer, answer_length, signed_answer, sizeof(signed_answer), signed_length)) {
            char header[256];
            const int header_length = std::snprintf(header, sizeof(header), "HTTP/1.1 200 OK\r\nContent-Type: application/sdp\r\nContent-Length: %d\r\nConnection: close\r\n\r\n", signed_length);
            SSL_write(ssl, header, header_length);
            SSL_write(ssl, signed_answer, signed_length);
        }
    } else {
        const char response[] = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        SSL_write(ssl, response, sizeof(response) - 1);
    }
    SSL_shutdown(ssl);
    SSL_free(ssl);
    closesocket(client);
}

int nethernet_https_start(const char *bind_address, uint16_t port, const char *certificate_path, const char *key_path, const char *identity_key_path, nethernet_answer_fn answer, void *user_data) {
    if (!answer || !certificate_path || !key_path) return -1;
    WSAData wsa{};
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) return -2;
    SSL_library_init();
    SSL_load_error_strings();
    const SSL_METHOD *method = TLS_server_method();
    SSL_CTX *context = SSL_CTX_new(method);
    if (!context || SSL_CTX_use_certificate_file(context, certificate_path, SSL_FILETYPE_PEM) != 1 || SSL_CTX_use_PrivateKey_file(context, key_path, SSL_FILETYPE_PEM) != 1) return -3;
    if (!load_identity_key(identity_key_path)) return -3;
    SOCKET listener = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (listener == INVALID_SOCKET) return -4;
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_port = htons(port);
    inet_pton(AF_INET, bind_address, &address.sin_addr);
    if (bind(listener, reinterpret_cast<sockaddr *>(&address), sizeof(address)) == SOCKET_ERROR || listen(listener, SOMAXCONN) == SOCKET_ERROR) return -5;
    rtcInitLogger(RTC_LOG_WARNING, rtc_log);
    SOCKET discovery = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (discovery == INVALID_SOCKET) return -6;
    sockaddr_in discovery_address{};
    discovery_address.sin_family = AF_INET;
    discovery_address.sin_port = htons(port);
    inet_pton(AF_INET, bind_address, &discovery_address.sin_addr);
    if (bind(discovery, reinterpret_cast<sockaddr *>(&discovery_address), sizeof(discovery_address)) == SOCKET_ERROR) {
        closesocket(discovery);
        return -7;
    }
    std::thread([discovery] { raknet_discovery(discovery); }).detach();
    std::thread([listener, context, answer, user_data] {
        while (true) {
            SOCKET client = accept(listener, nullptr, nullptr);
            if (client == INVALID_SOCKET) break;
            std::thread(https_connection, client, context, answer, user_data).detach();
        }
        SSL_CTX_free(context);
        closesocket(listener);
    }).detach();
    return 0;
}

static void RTC_API description_callback(int, const char *sdp, const char *type, void *ptr) {
    auto *peer = static_cast<Peer *>(ptr);
    if (sdp && type && std::strcmp(type, "answer") == 0) {
        peer->local_description = sdp;
        InterlockedExchange(&peer->description_ready, 1);
    }
    if (peer->callbacks.description) peer->callbacks.description(sdp, type, peer->callbacks.user_data);
}

static void RTC_API candidate_callback(int, const char *candidate, const char *mid, void *ptr) {
    auto *peer = static_cast<Peer *>(ptr);
    if (peer->callbacks.candidate) peer->callbacks.candidate(candidate, mid, peer->callbacks.user_data);
}

static void RTC_API gathering_callback(int, rtcGatheringState state, void *ptr) {
    auto *peer = static_cast<Peer *>(ptr);
    if (state == RTC_GATHERING_COMPLETE) InterlockedExchange(&peer->gathering_complete, 1);
}

static void RTC_API state_callback(int, rtcState state, void *ptr) {
    auto *peer = static_cast<Peer *>(ptr);
    if (peer->callbacks.state) peer->callbacks.state(static_cast<int>(state), peer->callbacks.user_data);
}

static void RTC_API data_channel_callback(int, int dc, void *ptr) {
    auto *peer = static_cast<Peer *>(ptr);
    char label[128]{};
    rtcGetDataChannelLabel(dc, label, sizeof(label));
    rtcSetUserPointer(dc, peer);
    rtcSetOpenCallback(dc, [](int id, void *data) {
        auto *p = static_cast<Peer *>(data);
        if (p->callbacks.open) p->callbacks.open(id, p->callbacks.user_data);
    });
    rtcSetClosedCallback(dc, [](int id, void *data) {
        auto *p = static_cast<Peer *>(data);
        if (p->callbacks.closed) p->callbacks.closed(id, p->callbacks.user_data);
    });
    rtcSetErrorCallback(dc, [](int id, const char *error, void *data) {
        auto *p = static_cast<Peer *>(data);
        if (p->callbacks.error) p->callbacks.error(id, error, p->callbacks.user_data);
    });
    rtcSetMessageCallback(dc, [](int id, const char *message, int size, void *data) {
        auto *p = static_cast<Peer *>(data);
        if (p->callbacks.message) p->callbacks.message(id, message, size, p->callbacks.user_data);
    });
    if (peer->callbacks.data_channel) peer->callbacks.data_channel(dc, label, peer->callbacks.user_data);
}

nethernet_datachannel_peer nethernet_datachannel_create(const char *bind_address, uint16_t port) {
    rtcConfiguration config{};
    config.bindAddress = bind_address;
    config.portRangeBegin = port;
    config.portRangeEnd = port;
    config.enableIceUdpMux = true;
    config.disableAutoNegotiation = true;
    auto *peer = new Peer;
    peer->id = rtcCreatePeerConnection(&config);
    if (peer->id < 0) {
        delete peer;
        return nullptr;
    }
    return peer;
}

int nethernet_datachannel_set_offer(nethernet_datachannel_peer handle, const char *offer) {
    auto *peer = static_cast<Peer *>(handle);
    if (!peer || peer->id < 0 || !offer) return RTC_ERR_INVALID;
    const int result = rtcSetRemoteDescription(peer->id, offer, "offer");
    return result;
}

int nethernet_datachannel_create_answer(nethernet_datachannel_peer handle, char *buffer, int size) {
    auto *peer = static_cast<Peer *>(handle);
    if (!peer || peer->id < 0 || !buffer || size <= 0) return RTC_ERR_INVALID;
    peer->local_description.clear();
    InterlockedExchange(&peer->description_ready, 0);
    InterlockedExchange(&peer->gathering_complete, 0);
    const int result = rtcSetLocalDescription(peer->id, "answer");
    if (result < 0) return result;
    for (int attempt = 0; attempt < 1000 && InterlockedCompareExchange(&peer->gathering_complete, 0, 0) == 0; ++attempt) Sleep(10);
    if (InterlockedCompareExchange(&peer->gathering_complete, 0, 0) == 0) {
        return RTC_ERR_NOT_AVAIL;
    }
    const int answer = rtcGetLocalDescription(peer->id, buffer, size);
    return answer;
}

int nethernet_datachannel_set_callbacks(nethernet_datachannel_peer handle, const nethernet_datachannel_callbacks *callbacks) {
    auto *peer = static_cast<Peer *>(handle);
    if (!peer || peer->id < 0) return RTC_ERR_INVALID;
    if (callbacks) peer->callbacks = *callbacks;
    rtcSetUserPointer(peer->id, peer);
    rtcSetLocalDescriptionCallback(peer->id, description_callback);
    rtcSetLocalCandidateCallback(peer->id, candidate_callback);
    rtcSetGatheringStateChangeCallback(peer->id, gathering_callback);
    rtcSetStateChangeCallback(peer->id, state_callback);
    rtcSetDataChannelCallback(peer->id, data_channel_callback);
    return RTC_ERR_SUCCESS;
}

int nethernet_datachannel_send(int channel, const void *data, int size) {
    if (!data || size <= 0) return RTC_ERR_INVALID;

    start_outgoing_worker();
    {
        std::lock_guard lock(outgoing_mutex);
        outgoing_messages.push_back({
            channel,
            std::vector<char>(static_cast<const char *>(data), static_cast<const char *>(data) + size),
        });
    }
    outgoing_condition.notify_one();
    return RTC_ERR_SUCCESS;
}

int nethernet_datachannel_channel_label(int channel, char *buffer, int size) {
    return rtcGetDataChannelLabel(channel, buffer, size);
}

void nethernet_datachannel_close(nethernet_datachannel_peer handle) {
    auto *peer = static_cast<Peer *>(handle);
    if (!peer) return;
    if (peer->id >= 0) {
        rtcClosePeerConnection(peer->id);
        rtcDeletePeerConnection(peer->id);
    }
    delete peer;
}
