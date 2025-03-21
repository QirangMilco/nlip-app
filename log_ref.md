# env_logger

[![crates.io](https://img.shields.io/crates/v/env_logger.svg)](https://crates.io/crates/env_logger)
[![Documentation](https://docs.rs/env_logger/badge.svg)](https://docs.rs/env_logger)

Implements a logger that can be configured via environment variables.

## Usage

### In libraries

`env_logger` makes sense when used in executables (binary projects). Libraries should use the [`log`](https://docs.rs/log) crate instead.

### In executables

It must be added along with `log` to the project dependencies:

```console
$ cargo add log env_logger
```

`env_logger` must be initialized as early as possible in the project. After it's initialized, you can use the `log` macros to do actual logging.

```rust
use log::info;

fn main() {
    env_logger::init();

    info!("starting up");

    // ...
}
```

Then when running the executable, specify a value for the **`RUST_LOG`**
environment variable that corresponds with the log messages you want to show.

```bash
$ RUST_LOG=info ./main
[2018-11-03T06:09:06Z INFO  default] starting up
```

The letter case is not significant for the logging level names; e.g., `debug`,
`DEBUG`, and `dEbuG` all represent the same logging level. Therefore, the
previous example could also have been written this way, specifying the log
level as `INFO` rather than as `info`:

```bash
$ RUST_LOG=INFO ./main
[2018-11-03T06:09:06Z INFO  default] starting up
```

So which form should you use? For consistency, our convention is to use lower
case names. Where our docs do use other forms, they do so in the context of
specific examples, so you won't be surprised if you see similar usage in the
wild.

The log levels that may be specified correspond to the [`log::Level`][level-enum]
enum from the `log` crate. They are:

   * `error`
   * `warn`
   * `info`
   * `debug`
   * `trace`

[level-enum]:  https://docs.rs/log/latest/log/enum.Level.html  "log::Level (docs.rs)"

There is also a pseudo logging level, `off`, which may be specified to disable
all logging for a given module or for the entire application. As with the
logging levels, the letter case is not significant.

`env_logger` can be configured in other ways besides an environment variable. See [the examples](https://github.com/rust-cli/env_logger/tree/main/examples) for more approaches.

### In tests

Tests can use the `env_logger` crate to see log messages generated during that test:

```console
$ cargo add log
$ cargo add --dev env_logger
```

```rust
fn add_one(num: i32) -> i32 {
    info!("add_one called with {}", num);
    num + 1
}

#[cfg(test)]
mod tests {
    use super::*;
    use log::info;

    fn init() {
        let _ = env_logger::builder().is_test(true).try_init();
    }

    #[test]
    fn it_adds_one() {
        init();

        info!("can log from the test too");
        assert_eq!(3, add_one(2));
    }

    #[test]
    fn it_handles_negative_numbers() {
        init();

        info!("logging from another test");
        assert_eq!(-7, add_one(-8));
    }
}
```

Assuming the module under test is called `my_lib`, running the tests with the
`RUST_LOG` filtering to info messages from this module looks like:

```bash
$ RUST_LOG=my_lib=info cargo test
     Running target/debug/my_lib-...

running 2 tests
[INFO my_lib::tests] logging from another test
[INFO my_lib] add_one called with -8
test tests::it_handles_negative_numbers ... ok
[INFO my_lib::tests] can log from the test too
[INFO my_lib] add_one called with 2
test tests::it_adds_one ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured
```

Note that `env_logger::try_init()` needs to be called in each test in which you
want to enable logging. Additionally, the default behavior of tests to
run in parallel means that logging output may be interleaved with test output.
Either run tests in a single thread by specifying `RUST_TEST_THREADS=1` or by
running one test by specifying its name as an argument to the test binaries as
directed by the `cargo test` help docs:

```bash
$ RUST_LOG=my_lib=info cargo test it_adds_one
     Running target/debug/my_lib-...

running 1 test
[INFO my_lib::tests] can log from the test too
[INFO my_lib] add_one called with 2
test tests::it_adds_one ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured
```

## Configuring log target

By default, `env_logger` logs to stderr. If you want to log to stdout instead,
you can use the `Builder` to change the log target:

```rust
use std::env;
use env_logger::{Builder, Target};

let mut builder = Builder::from_default_env();
builder.target(Target::Stdout);

builder.init();
```

## Stability of the default format

The default format won't optimise for long-term stability, and explicitly makes no guarantees about the stability of its output across major, minor or patch version bumps during `0.x`.

If you want to capture or interpret the output of `env_logger` programmatically then you should use a custom format.

# android_logger
## Send Rust logs to Logcat

[![Version](https://img.shields.io/crates/v/android_logger.svg)](https://crates.io/crates/android_logger)
[![CI status](https://github.com/rust-mobile/android_logger-rs/actions/workflows/ci.yml/badge.svg)](https://github.com/rust-mobile/android_logger-rs/actions/workflows/ci.yml/)


This library is a drop-in replacement for `env_logger`. Instead, it outputs messages to
android's logcat.

This only works on Android and requires linking to `log` which
is only available under android. With Cargo, it is possible to conditionally require
this library:

```toml
[target.'cfg(target_os = "android")'.dependencies]
android_logger = "0.13"
```

Example of initialization on activity creation, with log configuration:

```rust
#[macro_use] extern crate log;
extern crate android_logger;

use log::LevelFilter;
use android_logger::{Config,FilterBuilder};

fn native_activity_create() {
    android_logger::init_once(
        Config::default()
            .with_max_level(LevelFilter::Trace) // limit log level
            .with_tag("mytag") // logs will show under mytag tag
            .with_filter( // configure messages for specific crate
                FilterBuilder::new()
                    .parse("debug,hello::crate=error")
                    .build())
    );

    trace!("this is a verbose {}", "message");
    error!("this is printed by default");
}
```

To allow all logs, use the default configuration with min level Trace:

```rust
#[macro_use] extern crate log;
extern crate android_logger;

use log::LevelFilter;
use android_logger::Config;

fn native_activity_create() {
    android_logger::init_once(
        Config::default().with_max_level(LevelFilter::Trace),
    );
}
```

There is a caveat that this library can only be initialized once
(hence the `init_once` function name). However, Android native activity can be
re-created every time the screen is rotated, resulting in multiple initialization calls.
Therefore this library will only log a warning for subsequent `init_once` calls.

This library ensures that logged messages do not overflow Android log message limits
by efficiently splitting messages into chunks.

## License

Licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.