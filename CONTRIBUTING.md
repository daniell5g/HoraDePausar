# Contributing to Hora de Pausar

Contributions are welcome: bug fixes, new passages, translations, accessibility and design
improvements.

*Português: contribuições são bem-vindas. Abra uma issue ou um pull request; todo PR precisa da
aprovação do mantenedor antes de entrar no projeto.*

## How it works

1. Open an [issue](https://github.com/daniell5g/HoraDePausar/issues) for anything larger than a
   small fix, so we can agree on the idea first.
2. Fork the repository and create a branch from `main`.
3. Make your change and run the tests (see [Build and run](README.md#build-and-run) and
   [Tests](README.md#tests)).
4. Open a pull request against `main` describing what changed and why. Screenshots help for UI
   changes.

## Review and approval

`main` is protected. Nobody can push to it directly, and a pull request can only be merged after
the maintainer ([@daniell5g](https://github.com/daniell5g)) approves it. Pull requests that are not
approved are not merged.

## Guidelines

- Keep the app quiet and simple: one daily pause, no tracking, no data leaves the Mac.
- Bible text must come from a source whose license allows redistribution, with credit.
- Follow the existing architecture (`Core` for domain logic, `App` for the SwiftUI layer) and add
  tests for new behavior in `Core`.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
