#ifndef NETHERNET_DATACHANNEL_H
#define NETHERNET_DATACHANNEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *nethernet_datachannel_peer;

typedef void (*nethernet_description_fn)(const char *, const char *, void *);
typedef void (*nethernet_candidate_fn)(const char *, const char *, void *);
typedef void (*nethernet_state_fn)(int, void *);
typedef void (*nethernet_data_channel_fn)(int, const char *, void *);
typedef void (*nethernet_open_fn)(int, void *);
typedef void (*nethernet_closed_fn)(int, void *);
typedef void (*nethernet_message_fn)(int, const char *, int, void *);
typedef void (*nethernet_error_fn)(int, const char *, void *);
typedef int (*nethernet_answer_fn)(const char *, int, char *, int, void *);

typedef struct {
    nethernet_description_fn description;
    nethernet_candidate_fn candidate;
    nethernet_state_fn state;
    nethernet_data_channel_fn data_channel;
    nethernet_open_fn open;
    nethernet_closed_fn closed;
    nethernet_message_fn message;
    nethernet_error_fn error;
    void *user_data;
} nethernet_datachannel_callbacks;

nethernet_datachannel_peer nethernet_datachannel_create(const char *bind_address, uint16_t port);
int nethernet_datachannel_set_offer(nethernet_datachannel_peer peer, const char *offer);
int nethernet_datachannel_create_answer(nethernet_datachannel_peer peer, char *buffer, int size);
int nethernet_datachannel_set_callbacks(nethernet_datachannel_peer peer, const nethernet_datachannel_callbacks *callbacks);
int nethernet_datachannel_send(int channel, const void *data, int size);
int nethernet_datachannel_channel_label(int channel, char *buffer, int size);
void nethernet_datachannel_close(nethernet_datachannel_peer peer);
int nethernet_https_start(const char *bind_address, uint16_t port, const char *certificate_path, const char *key_path, const char *identity_key_path, nethernet_answer_fn answer, void *user_data);

#ifdef __cplusplus
}
#endif

#endif
