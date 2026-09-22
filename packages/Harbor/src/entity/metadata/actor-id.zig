var next_unique_id: i64 = 1;
var next_runtime_id: u64 = 1;

pub fn nextUniqueId() i64 {
    const id = next_unique_id;
    next_unique_id += 1;
    return id;
}

pub fn nextRuntimeId() u64 {
    const id = next_runtime_id;
    next_runtime_id += 1;
    return id;
}
