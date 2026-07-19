import 'package:flutter_bloc/flutter_bloc.dart';
import '../../storage/app_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final AppPreferences _appPreferences;

  ThemeBloc({required AppPreferences appPreferences})
      : _appPreferences = appPreferences,
        super(ThemeState(isDarkMode: appPreferences.isDarkMode)) {
    on<ThemeToggled>(_onThemeToggled);
  }

  Future<void> _onThemeToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final newValue = !state.isDarkMode;
    await _appPreferences.setDarkMode(newValue);
    emit(state.copyWith(isDarkMode: newValue));
  }
}