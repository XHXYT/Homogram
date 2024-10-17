# Homogram

Homogram is a 3rd-party Telegram client for [HarmonyOS Next](https://developer.huawei.com/consumer/cn/), driven by
ArkTS/ArkUI (UI-layer) and Rust (native-layer).

_This project is a hobby project and is not affiliated with either Telegram or Huawei._

## Roadmap

- [x] Login with phone number, authorizing with verification code and (optionally) password
- [x] Loading chats and most recent N messages
- [x] Rendering text and photo preview in messages
- [x] Sending text messages
- [x] Adaptive dark/light mode
- [ ] Full-screen view for medias
- [ ] Sending medias/files
- [ ] Reply to messages
- [ ] Loading more messages on scroll
- [ ] VOIP integration
- [ ] [HMS Push Kit](https://developer.huawei.com/consumer/cn/sdk/push-kit) (depends on Telegram's server-side
  support https://github.com/tdlib/td/issues/3057)
- [ ] Tons of features from official Telegram client...
- [ ] ...and even more!

## Building

### Prerequisites

- Windows or MacOS device which can run [DecEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) and
  Rust toolchain.
- Tested on Mate 60 Pro ALN-AL80, OpenHarmony SDK 5.0.0.71 API 12 Release and Rust 1.80.0. Other configurations may work
  but are not guaranteed.

1. [Obtain your own api_id](https://core.telegram.org/api/obtaining_api_id) for your application.
2. Fill out values into `features/home/src/main/rust/src/tg/config.rs` (there is a template file
   `config.rs.template`).
3. Setup Rust toolchain and ohos-rs for OpenHarmony: https://ohos.rs/docs/basic/quick-start.html
4. Build the native library in `features/home/src/main/rust`:
   ```shell
   cargo xtask dist ..\..\..\libs\arm64-v8a\
   ```
5. Correctly [configure](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-signing-V5) the signature
   information, and build the project in DevEco Studio.
6. Enjoy! (Or not, because it's still in heavy development)

PRs are welcome!

## Credits

- [grammers](https://github.com/Lonami/grammers), a set of Rust libraries to interact with Telegram's API.
- [ohos-rs](https://github.com/ohos-rs/ohos-rs), a`napi-rs` adaptation for OpenHarmony SDK.

These two projects are the backbone of Homogram and without them, this project would not be possible. Thanks to [@Lonami](https://github.com/Lonami),
[@richerfu](https://github.com/richerfu), and all contributors!

## License

This project is licensed under the Apache License, Version 2.0.
