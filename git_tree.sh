#!/bin/bash
# git_tree.sh - Скрипт для отображения дерева Git-репозитория
# Версия 1.1

# Функция справки
show_help() {
    echo "Использование: $0 [ПАРАМЕТРЫ] <папка>"
    echo ""
    echo "Параметры:"
    echo "  -h, --help     Показать эту справку"
    echo "  -c, --color    Использовать цветной вывод (по умолчанию: auto)"
    echo "  -n, --no-color Отключить цветной вывод"
    echo ""
    echo "Примеры:"
    echo "  $0 ./                    Текущая папка"
    echo "  $0 /путь/к/проекту      Конкретный проект"
    echo "  $0 --no-color ./        Без цветов"
    exit 0
}

# Обработка аргументов
COLOR_MODE="auto"
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -c|--color)
            COLOR_MODE="always"
            shift
            ;;
        -n|--no-color)
            COLOR_MODE="never"
            shift
            ;;
        -*)
            echo "Ошибка: Неизвестный параметр $1"
            echo "Используйте $0 --help для справки"
            exit 1
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

# Проверяем наличие папки
if [ -z "$PROJECT_DIR" ]; then
    echo "ОШИБКА: Укажите папку с проектом!"
    echo "Пример: $0 /home/user/myproject"
    echo "Используйте $0 --help для справки"
    exit 1
fi

# Проверяем существование папки
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ОШИБКА: Папка '$PROJECT_DIR' не найдена!"
    exit 1
fi

# ПРОВЕРКА: Установлен ли Git вообще
if ! command -v git &> /dev/null; then
    echo "ОШИБКА: Git не установлен в системе!"
    echo "Установите: sudo apt install git"
    exit 1
fi

# Проверяем Git-репозиторий
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "❌ В папке '$PROJECT_DIR' нет Git-репозитория!"
    echo "   Создайте репозиторий: git init"
    echo "   Текущий путь: $(pwd)"
    exit 0
fi

echo "✅ Найден Git-репозиторий в: $PROJECT_DIR"
echo "📅 Дата проверки: $(date '+%d.%m.%Y %H:%M:%S')"
echo "="=========================================""

# Переходим в папку проекта
cd "$PROJECT_DIR" || {
    echo "ОШИБКА: Не могу перейти в папку '$PROJECT_DIR'!"
    exit 1
}

# Получаем информацию о репозитории
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "неизвестно")
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "не настроен")

echo "📁 Репозиторий: $REPO_NAME"
echo "🌐 Удаленный: $REMOTE_URL"
echo ""

# 1. Показываем дерево коммитов
echo "🌳 ДЕРЕВО КОММИТОВ (последние 15):"
echo "=================================="
if git log --oneline --graph --all --decorate --color="$COLOR_MODE" 2>/dev/null | head -15; then
    TOTAL_COMMITS=$(git rev-list --all --count 2>/dev/null || echo "?")
    echo "... (всего коммитов: $TOTAL_COMMITS)"
else
    echo "⚠️  Не удалось получить историю коммитов"
fi
echo ""

# 2. Локальные ветки
echo "📌 ЛОКАЛЬНЫЕ ВЕТКИ:"
echo "=================="
if git branch --format='%(refname:short)' 2>/dev/null | while read branch; do
    echo "  $branch"
done; then
    LOCAL_COUNT=$(git branch --format='%(refname:short)' 2>/dev/null | wc -l)
    echo "  Всего: $LOCAL_COUNT"
else
    echo "  Нет локальных веток"
fi
echo ""

# 3. Удаленные ветки
echo "🌍 УДАЛЕННЫЕ ВЕТКИ:"
echo "=================="
if git branch -r --format='%(refname:short)' 2>/dev/null | grep -v "HEAD" | while read branch; do
    echo "  $branch"
done; then
    REMOTE_COUNT=$(git branch -r --format='%(refname:short)' 2>/dev/null | grep -v "HEAD" | wc -l)
    echo "  Всего: $REMOTE_COUNT"
else
    echo "  Нет удаленных веток"
fi
echo ""

# 4. Текущее состояние
echo "📍 ТЕКУЩЕЕ СОСТОЯНИЕ:"
echo "===================="
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "не определено")
echo "  Ветка: $CURRENT_BRANCH"

# Проверяем, есть ли изменения
if git status --porcelain 2>/dev/null | grep -q .; then
    echo "  ⚠️  Есть несохраненные изменения"
    UNTRACKED=$(git status --porcelain 2>/dev/null | wc -l)
    echo "  Файлов изменено: $UNTRACKED"
else
    echo "  ✓ Репозиторий чист"
fi

echo ""
echo "="=========================================""
echo "✅ Проверка завершена успешно!"
