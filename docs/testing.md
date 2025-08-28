# Integration Testing

This pipeline uses [nf-test](https://www.nf-test.com/) to define and run integration tests.

The `nf-test` suite includes
1. End-to-end integration tests using small but representative test datasets.
2. Workflow-level snapshot tests, comparing outputs to expected results.
3. Parameter testing for different pipeline configurations.

Tests can be triggered manually on any branch.

Tests will run automatically via GitHub Actions on any pull requests to `main`.

## Test Structure
```
tests/
├── .nftignore
├── main.nf.test
├── main.nf.test.snap
└── nextflow.config
```

## Running the Tests

Input data for the existing test conditions can be found in `assets/integration/`.

To run all tests locally: `nf-test test`

To run a specific test: `nf-test test tests/main.nf.test`

