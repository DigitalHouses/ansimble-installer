# DigitalHouses · Ansimble installer

Публичный установщик одного Debian 13 runner (CT1231) с Ansible и Semaphore на Proxmox VE. Репозитории разделены по назначению, без зависимости от legacy:

| Назначение | Источник |
| --- | --- |
| Установщик | `DigitalHouses/ansimble-installer` (PUBLIC) |
| Универсальный код и playbooks | `DigitalHouses/dh_ansible` (PUBLIC) |
| Site inventory и зашифрованный Vault | `DigitalHouses/dh_ansimble_fleet_detail` (**PRIVATE**) |

## Зафиксированный код для текущего `install.sh`

- `CODE_RELEASE=a6b16353f562b404bce6eb76801641af5a7457b0`
- `CODE_INSTALLER_BLOB=67254e213cd74bac280a7608278a79c06d3d937a`
- `FLEET_RELEASE=6dd57b2e35573a4883e70188590e8e595688bd71`
- GitHub CLI `2.102.0` — проверка SHA-256 скачанного архива.

Git SHA и Git blob проверяются **до** запуска bootstrap. GitHub OAuth выполняется владельцем через Device Login; временные данные авторизации очищаются после завершения. Полный Fleet Vault и OAuth-сессия не передаются в LXC.

## Запуск на чистом PVE

В доверенном root-терминале PVE, с site ID из приватного Fleet Detail в формате `<owner>-<type>`:

```bash
clear
SITE_ID="demo-office"
INSTALLER_REF="main"
SOURCE="$(curl -fsSL --retry 2 "https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/${INSTALLER_REF}/install.sh")"
test -n "$SOURCE" || exit 2
bash -c "$SOURCE" -- "$SITE_ID"
```

`demo-office` — **только синтетический пример**, для реального запуска укажите существующий site ID. Для воспроизводимой приёмки вместо плавающего `main` в `INSTALLER_REF` нужно задать **проверенный полный SHA коммита** этого установщика.

На занятом CT1231 без разрешения оператора ничего не удаляется. Существуют режимы `--resume`, `--resume-fresh`, `--resume-ansible`, `--resume-semaphore` — **только если текущее состояние полностью удовлетворяет строгим preflight-проверкам того же site ID**. Старый контейнер с другой идентичностью и/или отсутствующей инвентаризацией не является поддерживаемым resume.

## Контроль безопасности и приёмка

Установка запрещает перезапись существующего CT1231, требует проверки приватного Fleet и Vault master-password gate перед изменениями, затем явного подтверждения создания/продолжения. На runner создаётся локальная инвентаризация ровно одного объекта; ключи доступа владельца и общий Fleet Vault не передаются.

Успешные GitHub CI и синтетические тесты **не закрывают** полный Bootstrap E2E. Принятие требует отдельного разрешения на destructive fresh test, проверки PVE/CT, D-Bus, HTTPS Semaphore API, инвентаризации, двух read-only smoke-шаблонов и идемпотентности. Нельзя удалять CT, Debian-шаблоны, архивы или другие ресурсы до явного разрешения.
