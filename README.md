## Installation
Installation can be done through ``npm``:

```shell
npm i react-native-scroll-screenshot --save
```

## Usage
用于截取大于一屏幕的长图片

```js
import { NativeModules } from 'react-native';
```

```jsx
new Promise((resolve, reject) => {
  NativeModules.RNScrollScreenshot.takeScreenshot(ref, (error, uri) => {
    if (error) reject(error);
    resolve(uri);
  });
});
```
