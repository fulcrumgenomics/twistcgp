# Contributing to twistcgp

Thank you for your interest in contributing to twistcgp!
This pipeline is built on the [nf-core](https://nf-co.re/) template, so many of the community's conventions apply here.
Please review the [nf-core guidelines](https://nf-co.re/docs/guidelines/) for general best practices around Nextflow nf-core style pipeline development.

## Branching Model

Like most nf-core pipelines, we follow a **feature → dev → main** contribution pattern:

```text
feature/my-change ──PR──▶ dev ──PR──▶ main
```

- **`main`** — stable, release-ready code. Only receives merges from `dev`.
- **`dev`** — integration branch for ongoing work. All feature branches target `dev`.
- **feature branches** — short-lived branches for individual changes.
Create one from `dev` for each piece of work.

## How to Contribute

1. **Create a feature branch** from `dev`:

   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b <short_description>
   ```

2. **Make your changes.** Follow the coding standards described below.

3. **Run the test suite** locally before pushing:

   ```bash
   nextflow run main.nf -profile test,docker --outdir ./results
   ```

4. **Open a pull request** targeting `dev`. Fill in the PR template and describe your changes.

5. **Address CI feedback.** All checks (linting, pipeline tests) must pass before merging.

6. **Merge into `dev`** after review approval.

When `dev` is stable and ready for release, a maintainer will merge `dev` into `main` and tag a new version following [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Coding Standards

### Nextflow & nf-core Conventions

- Write modules and subworkflows in **Nextflow DSL2**.
- Follow the [nf-core module guidelines](https://nf-co.re/docs/guidelines/components/modules) when adding or updating modules.
- Use nf-core tooling to install community modules where available:

  ```bash
  nf-core modules install <tool_name>
  ```

- Place custom modules in `modules/local/` and custom subworkflows in `subworkflows/local/`.

### Formatting & Linting

This project uses [pre-commit](https://pre-commit.com/) hooks to enforce consistent formatting.
Install them once after cloning:

```bash
pip install pre-commit
pre-commit install
```

The hooks run automatically on each commit and include:

- [Prettier](https://prettier.io/) for code formatting
- Trailing whitespace removal
- End-of-file newline enforcement

You can run all hooks manually at any time:

```bash
pre-commit run --all-files
```

### Changelog

Update [CHANGELOG.md](../CHANGELOG.md) with a description of your changes under an `## [Unreleased]` section.
We follow the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

## CI/CD

Every push and pull request triggers the following GitHub Actions workflows:

- **Linting** — runs pre-commit hooks and `nf-core pipelines lint` to validate pipeline structure.
- **Pipeline tests** — executes the pipeline with the test profile across multiple Nextflow versions (`24.10.5`, `latest-everything`) and container engines (`conda`, `docker`, `singularity`).

## Reporting Issues

If you find a bug or have a feature request, please [open an issue](https://github.com/fulcrumgenomics/twistcgp/issues) on GitHub.

## Additional Resources

- [nf-core contributing guidelines](https://nf-co.re/docs/guidelines/)
- [nf-core module guidelines](https://nf-co.re/docs/guidelines/components/modules)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html)
- [nf-test documentation](https://www.nf-test.com/)
