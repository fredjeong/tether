# Tether — Product Requirements Document v0.1

## 문서 정보

| 항목 | 내용 |
|---|---|
| 제품명 | Tether |
| 문서 버전 | v0.1 |
| 대상 빌드 | 개인용 TestFlight 검증판 |
| 플랫폼 | iPhone only |
| 앱 언어 | English only |
| 문서 언어 | Korean, with finalized English UI copy |
| 배포 대상 | 제품 제작자 본인 1명 |
| 제품 단계 | 핵심 가설 검증 |

## 1. Product Summary

Tether는 사용자가 매일 완벽하게 행동하도록 압박하는 대신, 중요한 습관과의 연결을 놓지 않도록 돕는 iPhone용 habit tracker다.

사용자는 하루에 한 번 자신의 습관을 다음 세 상태 중 하나로 기록한다.

- **Done** — 계획한 수준으로 수행했다.
- **Light** — 평소보다 작게라도 수행했다.
- **Rest** — 의도적으로 쉬었다.

세 상태는 모두 사용자가 습관을 의식적으로 관리한 것으로 간주하며 Tether를 유지한다. 하루가 끝날 때까지 아무 상태도 선택하지 않은 경우에만 해당 연결이 종료된다.

### One-liner

> **A habit tracker where rest counts.**

### Emotional promise

> **You don't have to do it every day. Just don't let go.**

### Brand promise

> **Stay connected to who you want to become.**

## 2. Background and Problem

기존 habit tracker는 연속 수행과 목표 달성을 강조한다. 이 구조에서는 하루의 휴식이나 작은 실패가 streak 종료로 표현되고, 사용자가 실패 기록을 피하기 위해 앱과 습관을 함께 포기할 수 있다.

현실에서 습관의 강도는 매일 같지 않다. 계획대로 수행하는 날, 작은 행동만 가능한 날, 회복을 위해 쉬는 날이 모두 존재한다. Tether는 이 차이를 실패와 성공의 이분법으로 처리하지 않는다.

Tether가 구분하는 것은 다음과 같다.

- 행동과 휴식이 아니라 **의식적인 관리와 완전한 이탈**
- 매일의 완벽한 실행이 아니라 **되고 싶은 자신과의 지속적인 연결**

## 3. Product Hypothesis

### Primary hypothesis

사용자가 휴식과 작은 행동도 긍정적인 선택으로 기록할 수 있다면, 완벽한 수행만 인정하는 daily streak보다 습관을 더 오래 놓지 않을 것이다.

### Supporting hypotheses

1. **Rest**가 연결을 유지하면 휴식 뒤에 앱을 회피하는 감정적 비용이 줄어든다.
2. **Light**가 있으면 Done이 어려운 날의 완전한 이탈이 줄어든다.
3. 성공을 `execution streak`가 아닌 `connection streak`로 표현하면 사용자는 기록을 덜 평가적으로 받아들인다.
4. 하루 기록이 3초 안에 끝나면 장기 사용을 위한 상호작용 비용이 충분히 낮아진다.

## 4. Validation Goal

이번 빌드는 완성된 상용 앱이 아니라 제작자 본인이 실제 생활에서 Tether의 핵심 루프를 검증하기 위한 제품이다.

### 검증 기간

- 설치와 첫 설정 후 최소 14일간 실제 사용한다.
- 테스트를 위해 과거 날짜를 임의로 채우거나 Tether를 인위적으로 늘리지 않는다.

### 검증 질문

1. Done을 할 수 없는 날에도 Light 또는 Rest를 기록하기 위해 앱을 열게 되는가?
2. Rest를 기록한 다음 날에도 죄책감 없이 다시 앱을 열게 되는가?
3. 세 상태의 차이가 실제 생활에서 명확하고 자연스러운가?
4. Tether가 종료된 뒤 Reconnect가 다시 시작하기 쉽게 느껴지는가?
5. Tether라는 표현이 일반적인 streak보다 제품 철학을 잘 전달하는가?

### 개인 검증의 성공 기준

다음 조건을 모두 만족하면 핵심 루프를 다음 단계로 확장할 근거가 있다고 본다.

- 14일 검증 기간을 완료한다.
- 기록을 완료하는 일반적인 상호작용이 체감상 3초 이내다.
- Done을 수행하지 못한 날에도 Light 또는 Rest를 실제로 사용한다.
- 휴식 또는 연결 종료 뒤 앱을 의도적으로 회피하고 싶다는 감정이 기존 habit tracker보다 적다.
- 14일 종료 시 세 상태 중 제거하고 싶은 상태가 없고, 다시 14일 사용할 의향이 있다.

단일 사용자 검증이므로 retention이나 conversion을 통계적 지표로 해석하지 않는다. 이 단계의 결과는 제품 방향을 판단하기 위한 질적 증거다.

## 5. Target User

### 이번 빌드의 사용자

- 제품 제작자 본인 1명
- iPhone을 주 기기로 사용한다.
- 장기간 유지하고 싶은 습관이 최소 하나 있다.
- 기존의 성공/실패형 habit tracking에서 부담을 경험했거나, 그 문제를 직접 검증하고 싶다.

### 장기적인 제품 대상

해야 할 일을 더 많이 관리하려는 사람이 아니라, 중요한 습관을 완전히 포기하지 않고 현실적인 강도로 계속 이어가고 싶은 사람이다.

## 6. Product Principles

### 6.1 No guilt

실패, 손실, 마감 압박을 강조하지 않는다. 기록하지 못한 사실은 숨기지 않되 비난하는 언어를 사용하지 않는다.

### 6.2 Three seconds to check in

앱을 열고 오늘 상태를 선택하는 핵심 동작은 추가 입력이나 확인 단계 없이 끝나야 한다.

### 6.3 Rest is intentional

Rest는 회피가 아니라 의식적인 선택이다. Done, Light와 같은 수준의 유효한 일일 상태로 취급한다.

### 6.4 One thing at a time

이번 버전은 하나의 습관만 지원한다. 여러 습관을 관리하는 기능은 핵심 루프가 검증된 뒤 고려한다.

### 6.5 Progress without pressure

진행 상황은 사실대로 보여주되 달성률, 빨간 경고, 손실 카운트다운, 실패 배지로 압박하지 않는다.

### 6.6 Offline and private by default

핵심 기능은 네트워크 없이 동작하고, 개인 데이터는 기기에만 저장한다.

## 7. MVP Scope

### Included

1. 짧은 첫 실행 안내
2. 하나의 습관 생성
3. Done 기준과 Light 기준 설정
4. Done / Light / Rest 일일 기록
5. 당일 상태 변경
6. 현재 Tether 계산
7. 최장 Tether 계산
8. 미기록에 따른 Tether 종료
9. Reconnect 경험
10. 최근 기록 확인
11. 상태별 누적 횟수 확인
12. 하루 한 번 선택 가능한 로컬 알림
13. 습관과 알림 설정 편집
14. 전체 데이터 초기화

### Explicitly excluded

- 두 개 이상의 습관
- Habit slot과 unlock 시스템
- Home Screen widget
- Lock Screen widget
- Apple Watch
- iPad 전용 UI
- Android
- 로그인과 사용자 계정
- 서버와 원격 데이터베이스
- iCloud/CloudKit 동기화
- 백업과 기기 간 이전
- 외부 analytics SDK
- crash reporting SDK
- AI coach
- HealthKit, Calendar 또는 타사 서비스 연동
- 소셜, 친구, 공유, 커뮤니티, 리더보드
- 목표, todo, project 관리
- XP, level, badge, achievement
- 복잡한 통계와 성장 대시보드
- 앱 내 한국어 번역

## 8. Information Architecture

앱은 세 가지 주요 영역으로 구성한다.

### Today

- 현재 습관
- 현재 Tether
- 오늘의 기록 상태
- Done / Light / Rest 선택
- 아직 한 번도 기록하지 않은 경우 Start 안내
- 연결이 이미 종료된 경우 Reconnect 안내

### History

- 최근 날짜별 상태
- Current Tether
- Best Tether
- Done / Light / Rest 누적 횟수

### Settings

- 습관 이름 편집
- Done 기준 편집
- Light 기준 편집
- 일일 알림 켜기/끄기 및 시간 변경
- 전체 데이터 초기화
- 앱 버전 확인

Today와 History는 하단 탭으로 이동한다. Settings는 Today 화면 상단의 설정 버튼으로 연다.

## 9. Core User Flows

### 9.1 First launch and habit setup

1. 사용자가 앱을 처음 연다.
2. Tether의 세 상태와 연결 개념을 한 화면에서 읽는다.
3. `Set up my habit`을 선택한다.
4. 습관 이름, Done 기준, Light 기준을 입력한다.
5. 원하는 경우 하루 한 번 알림 시간을 설정한다.
6. 설정이 저장되고 Today 화면으로 이동한다.
7. 사용자는 즉시 오늘 상태를 기록할 수 있다.

### 9.2 Daily check-in

1. 사용자가 앱을 열면 Today 화면이 바로 표시된다.
2. 아직 기록하지 않았다면 `How was today?`와 세 상태 버튼이 보인다.
3. 사용자가 상태 하나를 선택한다.
4. 선택은 즉시 저장되며 별도의 확인 버튼을 요구하지 않는다.
5. 화면은 선택된 상태와 갱신된 Tether를 보여준다.

### 9.3 Change today's state

1. 오늘 이미 선택한 상태를 다시 누르거나 `Change`를 선택한다.
2. 세 상태가 다시 활성화된다.
3. 다른 상태를 선택하면 기존 오늘 기록을 교체한다.
4. 날짜당 기록은 항상 하나만 존재한다.

과거 날짜의 기록은 수정하거나 새로 입력할 수 없다. 이 제한은 사용자가 놓친 날을 사후에 채워 Tether의 의미를 바꾸지 않도록 한다.

### 9.4 Reconnect

1. 전날 또는 그 이전에 미기록일이 생겨 기존 Tether가 종료된다.
2. Today 화면은 손실을 강조하는 메시지 대신 `Reconnect today`를 보여준다.
3. 사용자가 Done, Light 또는 Rest를 선택한다.
4. 새로운 Tether가 1일부터 시작된다.
5. 종료된 과거 Tether와 기록은 History에 유지된다.

아직 Check-in 기록이 한 건도 없는 사용자는 Reconnect가 아니라 `Start your tether today`를 본다. 연결이 종료되었다는 표현은 최소 한 번 이상 기록한 뒤 실제 미기록일이 발생한 경우에만 사용한다.

### 9.5 Edit habit

1. 사용자가 Settings를 연다.
2. 습관 이름, Done 기준 또는 Light 기준을 변경한다.
3. 변경 내용은 이후 Today 화면에 반영된다.
4. 과거 기록과 Tether 계산은 유지된다.

### 9.6 Reset all data

1. 사용자가 Settings에서 `Reset all data`를 선택한다.
2. 삭제되는 내용을 설명하는 확인 창을 표시한다.
3. 사용자가 파괴적 동작을 한 번 더 확인한다.
4. 습관, 모든 기록, 알림 설정을 삭제하고 첫 실행 화면으로 돌아간다.

## 10. Daily State Requirements

| State | 의미 | Tether 유지 | 사용자 정의 문구 |
|---|---|---:|---|
| Done | 계획한 수준으로 수행 | Yes | Done 기준을 설정에서 확인 가능 |
| Light | 작은 버전으로 수행 | Yes | Light 기준을 설정에서 확인 가능 |
| Rest | 의도적으로 휴식 | Yes | 고정 설명 사용 |
| Missed | 해당 날짜에 기록 없음 | No | 선택 가능한 상태가 아닌 파생 상태 |

### Rules

- 한 날짜에는 Done, Light, Rest 중 최대 하나만 저장한다.
- Rest는 Done 및 Light와 동일하게 Tether를 유지한다.
- Missed는 데이터로 직접 입력하지 않는다.
- 사용자는 당일 기록만 추가하거나 변경할 수 있다.
- 당일 기록을 완전히 삭제하는 기능은 제공하지 않는다. 상태 변경만 허용한다.
- 앱이 열려 있는 동안 날짜가 바뀌면 화면과 계산 결과를 새 날짜 기준으로 갱신한다.

## 11. Tether Calculation

### Calendar basis

- 하루는 기기의 현재 현지 시간대에서 자정부터 다음 자정 직전까지다.
- 날짜 비교에는 기기의 현재 calendar와 time zone을 사용한다.
- 기록은 해당 순간의 현지 달력 날짜를 나타내는 날짜 키와 함께 저장한다.
- 사용자가 기기 시간이나 시간대를 임의로 변경해 기록을 조작하는 경우는 이번 검증 범위에서 방어하지 않는다.
- 모든 화면 날짜와 요일은 앱의 영어 전용 언어 정책에 맞춰 영어로 표시한다.

### When a day becomes Missed

- 오늘은 자정이 지나기 전까지 Missed가 아니다.
- 오늘 기록이 없어도 전날까지 이어진 Tether는 당일 동안 계속 현재 연결로 표시한다.
- 자정이 지난 시점에 직전 날짜의 기록이 없다면 기존 Tether가 종료된다.
- 습관 생성일보다 이전 날짜는 Missed로 간주하지 않는다.

### Current Tether

현재 Tether는 가장 최근의 유효한 연결에 포함된 연속 기록 일수다.

- 오늘 기록이 있으면 오늘부터 과거 방향으로 연속 기록 일수를 센다.
- 오늘 기록이 없고 어제 기록이 있으면 어제까지의 연속 기록 일수를 표시하면서 오늘 기록이 필요함을 알린다.
- Check-in이 한 건도 없으면 현재 Tether는 0이며 Start 상태다.
- Check-in이 한 건 이상 있지만 오늘과 어제 기록이 없으면 현재 Tether는 0이며 Reconnect 상태다.
- 오늘 기록이 있고 어제가 미기록이면 새로운 Tether는 1이다.

### Best Tether

Best Tether는 습관 생성 이후 기록 사이에 빈 날짜가 없는 가장 긴 연속 구간의 길이다. 과거 구간과 현재 구간을 모두 포함해 계산한다.

### Examples

| 기록 | 결과 |
|---|---|
| Done | Current 1 |
| Done → Light → Rest | Current 3 |
| Done → Light → 오늘 미기록, 자정 전 | Current 2, check-in pending |
| 기록 없음 | Current 0, Start |
| Done → Missed → 오늘 미기록 | Current 0, Reconnect |
| Done → Missed → Rest | Current 1, reconnected |

## 12. Screen Requirements

### 12.1 Welcome

목적은 제품 철학을 설명하고 설정을 시작하게 하는 것이다. 스와이프가 필요한 여러 장의 소개 화면은 사용하지 않는다.

필수 요소:

- Tether 이름
- One-liner
- Done / Light / Rest의 짧은 설명
- `Set up my habit` CTA

### 12.2 Habit Setup

필수 입력:

- Habit name: 1~40 characters
- Done means: 1~80 characters
- Light means: 1~80 characters

선택 입력:

- Daily reminder: off by default
- Reminder time: reminder를 켠 경우 필수

Validation:

- 필수 입력의 앞뒤 공백을 제거한다.
- 공백 제거 후 비어 있으면 저장할 수 없다.
- 글자 수 제한을 입력 화면에 자연스럽게 적용한다.

### 12.3 Today

필수 요소:

- 오늘 날짜
- 습관 이름
- `N days tethered`, Start 또는 Reconnect 상태
- `How was today?`
- Done / Light / Rest 선택
- 각 상태의 짧은 설명
- 기록 완료 뒤 현재 선택 상태와 `Change`

상태별 시각 표현은 색상만으로 구분하지 않는다. 텍스트 라벨과 아이콘 또는 형태를 함께 사용한다.

### 12.4 History

필수 요소:

- Current Tether
- Best Tether
- Done / Light / Rest 전체 횟수
- 습관 생성일부터 오늘까지의 최근 날짜별 상태
- Missed 날짜의 중립적인 표현

날짜별 기록은 오늘부터 과거 방향으로 정렬한 단순 목록으로 구현한다. 각 행은 영어로 표시한 날짜와 Done, Light, Rest 또는 No check-in 상태를 함께 보여준다. Habit 생성일부터 오늘까지 최대 최근 30일을 표시하며, Current Tether, Best Tether와 상태별 누적 횟수는 전체 기록을 기준으로 계산한다. 이번 버전에는 월간 calendar와 chart를 만들지 않는다.

### 12.5 Settings

필수 요소:

- Edit habit
- Daily reminder toggle
- Reminder time
- Notifications permission status
- Reset all data
- App version

## 13. Notifications

### Behavior

- 알림은 기본적으로 꺼져 있다.
- 사용자가 알림을 켤 때에만 시스템 권한을 요청한다.
- 하루에 최대 한 번, 사용자가 선택한 현지 시간에 예약한다.
- 알림을 끄거나 시간을 바꾸면 기존 예약을 취소하고 필요한 경우 새로 예약한다.
- 사용자가 알림 시간 전에 오늘 Check-in을 완료하면 오늘 알림을 취소하고 다음 날 알림을 예약한다.
- 사용자가 알림 시간 이후 Check-in을 완료하면 다음 날 알림만 예약한다.
- 앱 시작 또는 foreground 복귀 시 오늘 기록과 예약 상태를 다시 확인해 중복 알림이나 지난 알림을 정리한다.

### Permission denial

- 권한이 거부되어도 핵심 기록 기능은 정상 동작한다.
- Settings에서 권한이 꺼져 있음을 설명하고 iOS Settings로 이동할 수 있는 버튼을 제공한다.
- 반복해서 권한 요청 팝업을 띄우지 않는다.

### Notification copy

**Title:** `A moment for your habit`

**Body:** `Was today Done, Light, or Rest?`

압박을 유도하는 countdown, flame, 경고 문구는 사용하지 않는다.

## 14. Finalized English UI Copy

### Welcome

| Purpose | Copy |
|---|---|
| Product name | `Tether` |
| Headline | `Stay connected to who you want to become.` |
| Supporting copy | `You don't have to do it perfectly every day. Done, Light, and Rest all keep the connection alive.` |
| Primary CTA | `Set up my habit` |

### Habit setup

| Purpose | Copy |
|---|---|
| Screen title | `Set up your habit` |
| Habit field | `Habit name` |
| Habit example | `Workout` |
| Done field | `Done means` |
| Done example | `A full workout` |
| Light field | `Light means` |
| Light example | `Move for 10 minutes` |
| Reminder toggle | `Daily reminder` |
| Submit CTA | `Start my tether` |

### Today

| Purpose | Copy |
|---|---|
| Prompt | `How was today?` |
| Done label | `Done` |
| Done helper | `I did what I planned.` |
| Light label | `Light` |
| Light helper | `I did a smaller version.` |
| Rest label | `Rest` |
| Rest helper | `I chose to rest today.` |
| Active tether, singular | `1 day tethered` |
| Active tether, plural | `{count} days tethered` |
| Pending reminder | `You haven't checked in today.` |
| First check-in headline | `Start your tether today` |
| Completed message | `You're still connected.` |
| Change action | `Change` |

### Reconnect

| Purpose | Copy |
|---|---|
| Headline | `Reconnect today` |
| Supporting copy | `The connection ended, but your habit is still here.` |
| Prompt | `How was today?` |
| Completion | `Connected again.` |

### History

| Purpose | Copy |
|---|---|
| Tab title | `History` |
| Current metric | `Current Tether` |
| Best metric | `Best Tether` |
| Missed state | `No check-in` |
| Empty state | `Your check-ins will appear here.` |

### Settings

| Purpose | Copy |
|---|---|
| Screen title | `Settings` |
| Edit section | `Habit` |
| Reminder section | `Reminder` |
| Permission unavailable | `Notifications are turned off in iOS Settings.` |
| Permission action | `Open iOS Settings` |
| Reset action | `Reset all data` |
| Reset title | `Reset Tether?` |
| Reset body | `This will permanently delete your habit and all check-ins from this iPhone.` |
| Reset confirmation | `Reset` |
| Cancel | `Cancel` |

## 15. Data Requirements

### Habit

- unique identifier
- name
- Done description
- Light description
- creation timestamp
- last modified timestamp

앱에는 활성 Habit이 정확히 0개 또는 1개 존재한다.

### Daily Check-in

- unique identifier
- Habit identifier
- local calendar date key
- state: Done, Light, or Rest
- creation timestamp
- last modified timestamp

Habit과 local calendar date의 조합은 유일해야 한다.

### App Settings

- onboarding completion state
- reminder enabled state
- reminder local time

## 16. Data and State Flow

1. 앱이 시작되면 Habit 존재 여부를 확인한다.
2. Habit이 없으면 Welcome으로, 있으면 Today로 이동한다.
3. Today는 Habit, 오늘 Check-in, 기록 날짜 집합을 읽는다.
4. Tether 계산기는 날짜 집합으로 Current와 Best를 계산한다.
5. 사용자가 상태를 선택하면 오늘 Check-in을 생성하거나 교체한다.
6. 저장이 성공하면 Tether와 History 표시를 즉시 갱신한다.
7. 알림 설정 변경은 기기 설정 저장과 예약 갱신을 함께 수행한다.

UI는 Tether 숫자를 별도로 영구 저장하지 않는다. Check-in 기록에서 계산해 데이터 불일치를 방지한다.

## 17. Error and Edge-case Behavior

### Local save failure

- 선택이 저장되지 않았다면 성공 상태를 보여주지 않는다.
- 비난 없이 다시 시도할 수 있는 메시지를 표시한다.
- Copy: `Couldn't save your check-in. Please try again.`

### Date changes while app is open

- 앱이 foreground로 돌아오거나 시스템 날짜 변경 신호를 받으면 오늘 날짜를 다시 평가한다.
- 이전 날짜 화면에 새 기록을 저장하지 않는다.

### Time-zone changes

- 이후 화면과 새 기록에는 현재 기기 시간대를 사용한다.
- 이미 저장된 날짜 키를 소급 변환하지 않는다.
- 시간대 이동으로 보이는 날짜가 기대와 달라질 수 있다는 한계는 개인 검증에서 관찰 항목으로 남긴다.

### Notification scheduling failure

- 알림 예약 실패는 check-in을 방해하지 않는다.
- Settings에서 reminder가 활성화되지 않았음을 보여주고 다시 시도할 수 있게 한다.

### Corrupt or inconsistent local data

- 중복된 날짜 기록이 발견되면 가장 최근에 수정된 기록 하나를 표시 기준으로 사용한다.
- 앱이 종료되는 대신 최소한 Settings와 Reset 기능에 접근할 수 있어야 한다.

## 18. Accessibility and UX Quality

- Dynamic Type을 지원한다.
- VoiceOver에서 상태 이름, 설명, 선택 여부를 함께 읽을 수 있어야 한다.
- 주요 터치 영역은 최소 44×44pt다.
- 상태를 색상만으로 구분하지 않는다.
- 충분한 명도 대비를 유지한다.
- Reduce Motion 설정을 존중한다.
- 핵심 check-in은 한 손 사용과 세로 화면을 우선한다.
- 시스템 글꼴과 표준 iOS navigation을 우선해 별도 학습 비용을 줄인다.

## 19. Privacy and Security

- 사용자 계정을 만들지 않는다.
- 모든 제품 데이터는 앱의 로컬 저장소에만 보관한다.
- 네트워크 연결 없이 모든 핵심 기능이 동작한다.
- 외부 analytics, advertising, tracking SDK를 포함하지 않는다.
- 민감한 Health 데이터나 위치 데이터를 요청하지 않는다.
- 앱 삭제 또는 `Reset all data` 실행 시 로컬 데이터는 복구할 수 없다.

## 20. Non-functional Requirements

- 지원 기준은 iPhone과 iOS 17 이상으로 잡는다.
- 앱은 portrait 사용을 우선하되 시스템 회전으로 UI가 깨지지 않아야 한다.
- 일반적인 최신 iPhone에서 Today 화면이 지연 없이 표시되어야 한다.
- 네트워크가 없는 상태에서도 onboarding, check-in, History, Settings가 모두 동작해야 한다.
- 앱 종료와 재실행 뒤에도 기록과 설정이 유지되어야 한다.
- 날짜와 Tether 계산 로직은 UI와 분리되어 자동 테스트할 수 있어야 한다.

## 21. Acceptance Criteria

### Onboarding

- 새 설치에서 제품 설명과 Habit 설정을 완료할 수 있다.
- 필수 필드가 비어 있으면 Habit을 생성할 수 없다.
- 생성 뒤 추가 Habit을 만들 수 없다.

### Check-in

- 오늘 Done, Light 또는 Rest 중 하나를 선택할 수 있다.
- 선택은 앱 재실행 후에도 유지된다.
- 오늘 상태를 다른 상태로 변경할 수 있다.
- 과거 날짜를 새로 기록하거나 수정할 수 없다.

### Tether

- Done, Light, Rest는 모두 연결 일수를 1일 유지 또는 증가시킨다.
- 미기록일이 지나면 기존 Tether가 종료된다.
- 미기록 다음 기록은 1일부터 새 Tether를 시작한다.
- Current와 Best 계산이 문서의 예시와 일치한다.

### History

- 습관 생성일부터 오늘까지의 최근 상태를 확인할 수 있다.
- Done, Light, Rest, No check-in을 구분할 수 있다.
- Current Tether, Best Tether, 상태별 횟수가 정확하다.

### Reminder

- 사용자가 알림을 켤 때만 권한을 요청한다.
- 설정한 시간에 하루 한 번 알림이 예약된다.
- 알림 시간 전에 오늘 Check-in을 완료하면 그날 알림이 오지 않는다.
- 권한 거부가 앱의 다른 기능을 막지 않는다.

### Reset

- 확인 과정을 거쳐 Habit, Check-in, reminder 설정을 모두 삭제할 수 있다.
- 초기화 뒤 Welcome 화면으로 돌아간다.

## 22. Test Strategy

### Automated unit tests

- Current Tether 계산
- Best Tether 계산
- Done / Light / Rest가 동일하게 연결을 유지하는지 검증
- 중간 Missed에 따른 구간 분리
- 오늘 미기록과 자정 이후 Missed의 차이
- Habit 생성일 이전 날짜 제외
- 단수/복수 Tether 문구
- 입력 trim 및 길이 제한

### Integration tests

- Habit 생성과 재실행 후 복원
- 오늘 Check-in 생성과 변경
- Reset 후 데이터 제거
- reminder 설정 변경과 예약 갱신
- 오늘 Check-in 완료에 따른 당일 reminder 취소와 다음 날 예약

### UI tests

- 첫 실행부터 첫 Check-in까지의 주요 흐름
- Today에서 세 상태 선택
- History 접근
- Settings에서 Habit 편집
- 알림 권한 거부 상태
- 전체 데이터 초기화

### Manual TestFlight checks

- 실제 자정 전후 상태 변화
- 앱을 하루 이상 열지 않았을 때 Reconnect
- 비행기 모드에서 전체 핵심 기능
- 앱 종료와 기기 재부팅 후 데이터 유지
- Dynamic Type과 VoiceOver 기본 사용성
- 14일 dogfooding journal을 통한 감정적 부담과 상태 선택의 자연스러움 기록

## 23. Validation Journal

별도의 서버 analytics 대신 14일 동안 다음 항목을 간단히 메모한다.

- 오늘 선택한 상태와 그 이유
- 앱을 열기 싫었는지 여부
- 상태 선택이 애매했는지 여부
- Rest가 정당한 휴식으로 느껴졌는지, 쉬운 회피로 느껴졌는지
- 기록 과정에서 불필요한 단계가 있었는지
- Reconnect가 발생했다면 다시 시작하기가 어땠는지

이 메모는 앱 기능으로 만들지 않는다. 개인 메모 도구를 사용한다.

## 24. Risks and Mitigations

| Risk | 영향 | 이번 버전의 대응 |
|---|---|---|
| Rest를 지나치게 쉽게 선택 | 습관 행동의 의미 약화 | 상태 분포와 14일 journal을 함께 관찰 |
| 한 명만 테스트 | 일반화 불가능 | 핵심 UX 결함 발견과 자기 사용성 검증으로 목적 제한 |
| 자정/시간대 계산 오류 | Tether 신뢰 훼손 | 날짜 로직 분리 및 경계 자동 테스트 |
| 알림이 압박으로 느껴짐 | 제품 철학 훼손 | 중립적 copy, 하루 최대 한 번, 기본 off |
| 로컬 전용 데이터 손실 | 검증 기록 소실 | 현재 단계의 명시적 제약으로 수용, reset 경고 제공 |
| 기능을 너무 많이 추가 | 핵심 가설 판별 어려움 | Included 목록 밖 기능은 다음 단계까지 보류 |

## 25. Post-validation Decision

14일 검증 뒤 다음 중 하나를 선택한다.

### Continue

핵심 루프가 자연스럽고 다시 사용할 의향이 있으면 소수 외부 TestFlight를 준비한다. 이때 crash reporting, 최소한의 privacy-conscious analytics, 피드백 수집 방식을 별도 검토한다.

### Revise

가치는 느껴지지만 상태 정의, Tether 표현 또는 Reconnect 경험이 어색하면 핵심 루프만 수정하고 다시 14일 검증한다.

### Stop

Rest와 Light가 행동 유지에 도움을 주지 않거나 일반 streak보다 의미가 약하면 다중 습관, widget 등으로 확장하지 않는다.

## 26. Open Product Questions for the 14-day Test

이 질문들은 구현 전 결정 사항이 아니라 실제 사용으로 답할 검증 항목이다.

1. Rest 사용에 제한이나 추가 reflection이 필요한가?
2. `days tethered`가 자연스러운 영어 표현으로 느껴지는가?
3. History에 상태별 횟수가 도움이 되는가, 평가처럼 느껴지는가?
4. 알림은 습관을 의식하게 하는가, 압박을 만드는가?
5. Reconnect copy가 충분히 따뜻하면서도 상황을 명확히 설명하는가?
6. 한 개의 Habit 제한이 집중을 돕는가, 답답하게 느껴지는가?

## 27. Definition of Done for v0.1

v0.1은 다음 조건을 충족할 때 TestFlight 검증 준비가 끝난 것으로 본다.

- Included scope의 모든 acceptance criterion이 통과한다.
- 날짜 및 Tether 자동 테스트가 통과한다.
- 주요 사용자 흐름 UI test가 통과한다.
- 실제 iPhone에서 첫 설정, check-in, 날짜 변경, Reconnect, History, reminder, Reset을 확인한다.
- English UI에 미완성 문구나 한국어 문자열이 남아 있지 않다.
- TestFlight 내부 배포 빌드를 설치할 수 있다.
- 알려진 결함과 검증 journal 시작일을 기록한다.
