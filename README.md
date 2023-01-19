# intlx_generator

Use the `intl` plugin with dynamic strings.

You can now get translation using a dynamic string key in Flutter.

## Usage

Add the plugin to your `dev_dependencies`:

```yaml
intlx_generator:
    git:
      url: "https://github.com/BitizenWallet/intlx_generator.git"
      ref: main
```

Run the generator function:

```shell
flutter pub get
flutter pub run intlx_generator
```

Use the plugin:

```dart
import "package:your_app/intlx.dart
# The argument list is optional.
AppLocalisations.of(context).intlx("some_key", []);
```
