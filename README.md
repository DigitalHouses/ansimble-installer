# DigitalHouses · Ansimble installer

Публичная точка входа для единого bootstrap. **Никакой зависимости от прежних GitHub-репозиториев**:

| Назначение | Единственный источник |
| --- | --- |
| Публичный installer | `DigitalHouses/ansimble-installer` |
| Ansible, Semaphore bootstrap, роли и playbooks | `DigitalHouses/dh_ansible` |
| Инвентаризации домов и зашифрованные секреты | `DigitalHouses/dh_ansimble_fleet_detail` (всегда private) |

## Зафиксированные ревизии

`install.sh` версии `7b1d7bb7ed99b4a95db79c2eead95146ec7093a7` использует:

- код: `2f05b6ecaa2113057046ddbbf2d2dbf0235d09b7` из `dh_ansible`;
- Fleet Detail: `6dd57b2e35573a4883e70188590e8e595688bd71`;
- отдельно проверяемый Git blob файла `bootstrap/semaphore-host-install.py`;
- официальный GitHub CLI 2.102.0 с проверкой SHA-256.

Изменение одного репозитория **не** переводит автоматически другой на незакреплённую ревизию.

## Запуск на чистом PVE

Работа из доверенного root-терминала PVE. Для дома «Асыл-Мура» канонический идентификатор — `serzhan-home` (owner=`serzhan`, type=`home`). Старый псевдоним `home` больше не используется.

```bash
clear
SITE_ID="serzhan-home"
SOURCE="$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/7b1d7bb7ed99b4a95db79c2eead95146ec7093a7/install.sh)"
test -n "$SOURCE" || exit 2
bash -c "$SOURCE" -- "$SITE_ID"
```

Для восстановления на **уже проверенном** контейнере второй аргумент может быть одним из `--resume`, `--resume-fresh`, `--resume-ansible`, `--resume-semaphore`. Bootstrap проверяет текущее состояние и не удаляет существующий CT автоматически.

При запуске оператор авторизует GitHub через device login, вводит Fleet Vault master password локально и подтверждает создание CT1231. Из PVE выполняются только управление гостем и передача проверенных файлов. Постоянные Git, Ansible, Node.js, Desktop Commander и Semaphore работают **в гостевом LXC**, не на PVE.

## Граница принятия

В настоящее время `dh_ansible` всё ещё **private**. Прежде чем сделать его публичным, требуется отдельная проверка текущего дерева **и всей Git-истории** на приватные данные. Пока он private, штатный импорт `Public Git (none)` из Semaphore не сработает.

Имя сайта в Fleet Detail приведено к `serzhan-home`. Желаемый hostname runner при новой установке — `ansimble-serzhan-home`. Текущий тестовый CT1231 пока не переименован: он продолжает работу до чистого E2E, при котором будет пересоздан.

Рабочий домашний CT1231 не удалять только ради теста загрузчика. Полное принятие Bootstrap = запуск на чистом PVE с удалённым тестовым CT и Debian-шаблоном, затем автоматическое создание LXC, Ansible, Semaphore, Desktop Commander, проверка веб-UI, smoke playbooks и повторного apply. Только после этого можно считать старые репозитории ненужными и безопасно удалить их отдельно.

**Текущий статус:** публичный loader проверен статическими и негативными тестами, но чистый bootstrap E2E ещё не принят.
