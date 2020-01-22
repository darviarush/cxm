# NAME

`cpm`

**Cpan eXtend packet Manager**

# SYNOPSIS

`cpm` может устанавливать проекты из `git`-репозиториев в интернете, вроде `github.com`, однако не устанавливает их зависимости.

`cxm` решает эту проблему: он просто вызывает `cpm` для каждого из таких зависимостей рекурсивно.

# DESCRIPTION

Примеры:

```sh

# Установить все модули из cpanfile с зависимостями глобально
$ cxm install -g

# Установить конкретный модуль с зависимостями в локальный каталог и добавить его в cpanfile
$ cxm add App::cpanminus

# Установить конкретный модуль с зависимостями локально
$ cxm install App::cpanminus

# Удалить все модули из cpanfile локально
$ cxm rm

# Деинсталлировать конкретный модуль глобально
$ cxm rm -g App::cpanminus

# Деинсталлировать конкретный модуль глобально и удалить его из cpanfile
$ cxm del -g App::cpanminus

# Пройтись по исходникам и найти все внешние модули подключённые через `use` или `require`
$ cxm find . > cpanfile

```

# LICENSE

Copyright (C) Yaroslav O. Kosmina.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>
