import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../storage/app_preferences.dart';
import 'locale_event.dart';
import 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final AppPreferences _appPreferences;

  LocaleBloc({required AppPreferences appPreferences})
      : _appPreferences = appPreferences,
        super(LocaleState(locale: Locale(appPreferences.localeCode))) {
    on<LocaleChanged>(_onLocaleChanged);
  }

  Future<void> _onLocaleChanged(LocaleChanged event, Emitter<LocaleState> emit) async {
    await _appPreferences.setLocaleCode(event.locale.languageCode);
    emit(state.copyWith(locale: event.locale));
  }
}