# DigitalHouses · Ansimble installer

Публичная точка входа для единого bootstrap. **Никакой зависимости от прежних GitHub-репозиториев**:

| Назначение | Единственный источник |
| --- | --- |
| Публичный installer | `DigitalHouses/ansimble-installer` |
| Ansible, Semaphore bootstrap, роли и playbooks | `DigitalHouses/dh_ansible` |
| Инвентаризации домов и зашифрованные секреты | `DigitalHouses/dh_ansimble_fleet_detail` (всегда private) |

## Зафиксированные ревизии

`install.sh` версии `673e45919051b2eb206205b059d5b66181d64513` использует:

- код: `267986be6db414a72fe4476656ebcdb230ce77d6` из `dh_ansible`;
- Fleet Detail: `acde4a83668a0285fe05f54b515211c0b2663ef1`;
- отдельно проверяемый Git blob файла `bootstrap/semaphore-host-install.py`;
- официальный GitHub CLI 2.102.0 с проверкой SHA-256.

Изменение одного репозитория **не** переводит автоматически другой на незакреплённую ревизию.

## Запуск на чистом PVE

Работа из доверенного root-терминала PVE. `SITE_ID` нужно заменить на **утверждённый** ID дома формата `<owner>-<type>`. Нельзя использовать старый псевдоним `home` до миграции его inventory.

```bash
clear
SITE_ID="owner-home" # пример синтаксиса, не существующий объект
SOURCE="$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/673e45919051b2eb206205b059d5b66181d64513/install.sh)"
test -n "$SOURCE" || exit 2
bash -c "$SOURCE" -- "$SITE_ID"
```

Для восстановления на **уже проверенном** контейнере второй аргумент может быть одним из `--resume`, `--resume-fresh`, `--resume-ansible`, `--resume-semaphore`. Bootstrap проверяет текущее состояние и не удаляет существующий CT автоматически.

При запуске оператор авторизует GitHub через device login, вводит Fleet Vault master password локально и подтверждает создание CT1231. Из PVE выполняются только управление гостем и передача проверенных файлов. Постоянные Git, Ansible, Node.js, Desktop Commander и Semaphore работают **в гостевом LXC**, не на PVE.

## Граница принятия

В настоящее время `dh_ansible` всё ещё **private**. Прежде чем сделать его публичным, требуется отдельная проверка текущего дерева **и всей Git-истории** на приватные данные. Пока он private, штатный импорт `Public Git (none)` из Semaphore не сработает.

Также прежний site ID `home` в Fleet Detail пока не переведён на формат `<owner>-<type>`; чистый E2E для домашнего объекта должен ждать утверждённого имени и совместимого inventory.

Рабочий домашний CT1231 не удалять только ради теста загрузчика. Полное принятие Bootstrap = запуск на чистом PVE с удалённым тестовым CT и Debian-шаблоном, затем автоматическое создание LXC, Ansible, Semaphore, Desktop Commander, проверка веб-UI, smoke playbooks и повторного apply. Только после этого можно считать старые репозитории ненужными и безопасно удалить их отдельно.

**Текущий статус:** публичный loader проверен статическими и негативными тестами, но чистый bootstrap E2E ещё не принят.
