# Protocol: Release Build

## Steps
1. Product Owner confirms feature-complete for release.
2. QA Lead executes full regression suite.
3. Security Tester executes security test suite.
4. Accessibility QA verifies WCAG compliance.
5. version_bumper bot confirms version bumped.
6. DevOps builds Flutter Windows executable.
7. MSIX Packager creates signed MSIX package.
8. QA Lead executes install/uninstall test on clean machine.
9. CTO authorizes release.
10. Deployment Specialist distributes package.

## Quality Gates
- [ ] Full regression pass
- [ ] Security test pass
- [ ] Accessibility test pass
- [ ] Version bumped (pubspec.yaml, msix_config.yaml, CHANGELOG.md)
- [ ] MSIX signed with valid certificate
- [ ] Install test passed on clean machine
- [ ] CTO authorization received

## Rollback
- Keep previous MSIX package available for rollback.
- Rollback decision within 1 hour of deployment if critical issue found.