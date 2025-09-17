zig build-exe ./src/main.zig -O ReleaseFast --name main_release_fast
zig build-exe ./src/main.zig -O ReleaseSafe --name main_release_safe
zig build-exe ./src/main.zig -O ReleaseSmall --name main_release_small
zig build-exe ./src/main.zig -O Debug --name main_debug

hyperfine --warmup 3 --runs 5 "./main_release_fast"
hyperfine --warmup 3 --runs 5 "./main_release_safe"
hyperfine --warmup 3 --runs 5 "./main_release_small"
hyperfine --warmup 3 --runs 5 "./main_debug"
