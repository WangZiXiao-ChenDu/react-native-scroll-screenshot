import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import {
  View,
  StyleSheet,
  Text,
  TouchableOpacity,
  NativeModules,
  findNodeHandle,
} from 'react-native';

const RNScrollScreenshot = NativeModules.RNScrollScreenshot;

class App extends React.Component {
  componentWillUnmount () {
    subscription.remove();
  }

  render() {
    const ref = findNodeHandle(this.props.nodeRef);
    return (
      RNScrollScreenshot.takeScreenshot(ref, (error, uri) => {
        if (error) {
          console.log(error);
        } else {
            console.log(uri);
        }
      });
    )
  }
}
