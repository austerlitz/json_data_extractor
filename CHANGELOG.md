# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.05] -  2025-05-13

### Added
- Added schema reuse functionality for improved performance when processing multiple data objects with the same schema
  - New `JsonDataExtractor.with_schema` class method to create an extractor with a pre-processed schema
  - New `SchemaCache` class to store and reuse schema information
  - New `extract_from` method to extract data using a cached schema
- Performance improvements by pre-compiling JsonPath objects and caching schema elements

## [0.1.04] - 2025-04-26

- Use Oj for json dump 
- Use json path caching
