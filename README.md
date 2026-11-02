# NOTEBOX

제텔카스텐 방식의 노트박스를 만드는 Flutter 프로젝트입니다.

## 개발 시작

Flutter stable SDK를 준비하고 다음 명령을 실행합니다. 초기 환경에서 검증한 SDK 커밋은 `c197ca5199e9ee5661e865596c9c07294dfab51c`입니다.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d chrome
```

Android 실행에는 Android SDK와 기기 또는 에뮬레이터가 필요합니다. iOS 빌드는 macOS와 Xcode가 필요합니다.

## Codex에서 이어서 작업

GitHub의 이 저장소를 선택하고 최신 커밋을 가져오세요. 클라우드 환경 스냅샷과 Git 커밋은 별개입니다. 소스와 작업 안내는 Git에 보관하고 SDK·캐시·빌드 결과는 커밋하지 않습니다.

현재 범위와 다음 작업은 [작업 인계](docs/HANDOFF.md)를 참고하세요.

## GitHub Pages

`.github/workflows/pages.yml`은 main 변경 또는 수동 실행 시 분석·테스트 후 웹 빌드를 GitHub Pages에 배포합니다. 저장소 Settings → Pages → Build and deployment → Source를 **GitHub Actions**로 지정하세요.

기본 프로젝트 주소: https://dogpoo-net.github.io/NOTEBOX_APP_FLUTTER/

프로젝트 경로에 맞춰 `--base-href /NOTEBOX_APP_FLUTTER/`로 빌드합니다. 별도 서버·SSH 인증은 필요 없습니다. 실제 공개 여부는 Actions 배포 성공 후 확인하세요. 현재 메모는 메모리 기반으로 새로고침 시 초기화됩니다.
