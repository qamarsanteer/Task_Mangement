import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object?> get props => [];
}

class LocaleChanged extends LocaleEvent {
  final Locale locale;
  const LocaleChanged(this.locale);
  @override
  List<Object?> get props => [locale];
}