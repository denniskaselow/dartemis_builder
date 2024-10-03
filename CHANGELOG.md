# Changelog

### 0.4.0
### Enhancements
- supports dartemis 0.4.0
- can handle named and optional parameters

## 0.3.1
### Minor Changes
- fixed error in code example in README.md
- updated analyzer dependency to ^5.2.0

## 0.3.0
### Enhancements
- **BREAKING CHANGE:** generated code now creates a `processEntity` method with the
  components as parameters; it's no longer required to use the mappers

## 0.2.2+1
### Minor Changes
- updated analyzer dependency from ^4.0.0 to ^5.0.0

## 0.2.2
### Enhancements
- supports super parameters (requires SDK >= 2.17)

## 0.2.1
### Minor Changes
- updated analyzer dependency from ^2.7.0 to ^4.0.0 

## 0.2.0
### Enhancements
- supports NNBD
- creates OptionalMapper for oneOf-Mappers 

## 0.1.1
### Minor Changes
- updated upper bound of analyzer dependency
### Bugfix
- correct handling of managers/systems with type parameter

## 0.1.0+2
### Minor Changes
- updated upper bound of analyzer dependency

## 0.1.0+1
### Minor Changes
- increased lower bound for Dart SDK from 2.0.0 to 2.3.0
- more aggressive analysis_options.yaml, fixed hints 
- reduced lower bound of analyzer dependency to work with angular 6.0.0-alpha

## 0.1.0

- Initial version
