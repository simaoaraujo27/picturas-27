.PHONY: test test-all test-python test-node test-api test-e2e test-unit test-integration test-strict test-security test-resilience test-performance test-known-failures test-fixtures

test-fixtures:
	.venv/bin/python tests/fixtures/generate.py

test test-strict: test-fixtures
	python3 scripts/regression.py all

test-all: test-fixtures
	python3 scripts/regression.py full

test-node:
	python3 scripts/regression.py node

test-python:
	python3 scripts/regression.py python

test-unit:
	python3 scripts/regression.py unit

test-api: test-fixtures
	python3 scripts/regression.py api

test-integration: test-fixtures
	python3 scripts/regression.py integration

test-e2e: test-fixtures
	python3 scripts/regression.py e2e

test-security: test-fixtures
	python3 scripts/regression.py security

test-resilience: test-fixtures
	python3 scripts/regression.py resilience

test-performance: test-fixtures
	python3 scripts/regression.py performance

test-known-failures: test-fixtures
	python3 scripts/regression.py known-failures
