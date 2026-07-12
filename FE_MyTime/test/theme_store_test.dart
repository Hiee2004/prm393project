import 'package:flutter_test/flutter_test.dart';
import 'package:project/services/my_time_store.dart';

void main() {
  test('profile and settings keep the same theme', () {
    final store = MyTimeStore.instance;
    final originalProfile = store.profile;
    final originalSetting = store.setting;

    addTearDown(() {
      store.updateProfile(originalProfile);
      store.updateSetting(originalSetting);
    });

    store.updateSetting(store.setting.copyWith(themeMode: 'Winter'));
    expect(store.profile.themeMode, 'Winter');

    store.updateProfile(store.profile.copyWith(themeMode: 'Lunar New Year'));
    expect(store.setting.themeMode, 'Lunar New Year');
  });
}
