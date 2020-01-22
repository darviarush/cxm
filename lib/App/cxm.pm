package App::cxm;

use common::sense;
use Pod::Usage;
use ExtUtils::Installed;
use ExtUtils::Packlist;
use App::cpm::CLI;

our $VERSION = "0.01";

# конструктор
sub new {
	my ($cls) = @_;
	bless {@_}, ref $cls || $cls;
}

# запуск
sub run {
	my ($self) = @_;
	
	$self->{cmd} = shift @{$self->{args}};
	
	given($self->{opt}->{help}? "help": $self->{cmd}) {
		$self->help when "help";
		$self->install when "install";
		$self->rm when "rm";
		$self->add when "add";
		$self->del when "del";
		$self->find when "find";
		default { $self->usage($m) }
	}

	$self
}

# выводит помощь на STDOUT
sub help {
	my ($self) = @_;
	pod2usage(1);
	$self
}

# выводит помощь на STDOUT
sub usage {
	my ($self) = @_;
	pod2usage(2);
	$self
}

# стрингифицирует аргументы
sub args {
	my ($self) = @_;
	join " ", @{$self->{args}}
}

# рекурсивно инсталлирует пакеты
sub install {
	my $self = shift;

	my $cpm = App::cpm::CLI->new;
	
	# --with-requires,   --without-requires   (default: with)
    #  --with-recommends, --without-recommends (default: without)
    #  --with-suggests,   --without-suggests   (default: without)
    #  --with-configure,  --without-configure  (default: without)
    #  --with-build,      --without-build      (default: with)
    #  --with-test,       --without-test       (default: with)
    #  --with-runtime,    --without-runtime    (default: with)
    #  --with-develop,    --without-develop    (default: without)
	my $is_errors = $cpm->run("install", $self->is_glob? "-g": (), 
		"--without-requires",
		"--without-build",
		"--without-test",
		"--without-runtime",
		@_);
	
	$self
}

# инсталлируем и добавляем зависимость в cpanfile
sub add {
	my $self = shift;
	
	$self->nonzero_args(@_);
	
	for my $module (@_) {
		$self->install($module);
		next if $!;
	
		eval("require $pkg");
		my $version = ${"\$${pkg}::VERSION"};
		
		$self->cpanfile(sub {
			s/\brequires\s+'\Q$pkg\E'.*\n?|$/\nrequires '$pkg', '$version';\n/
		});
	}
	
	$self
}

# удаляет пакеты
sub rm {
	my $self = shift;
	
	$self->nonzero_args(@_);
	
	for my $module (@{$self->{args}}) {
	
		my $installed_modules = ExtUtils::Installed->new;

		# iterate through and try to delete every file associated with the module
		foreach my $file ($installed_modules->files($module)) {
			print "removing $file\n";
			unlink($file)? : warn "could not remove $file: $!\n";
		}

		# delete the module packfile
		my $packfile = $installed_modules->packlist($module)->packlist_file;
		print "removing $packfile\n";
		unlink $packfile or warn "could not remove $packfile: $!\n";

		# delete the module directories if they are empty
		foreach my $dir (sort($installed_modules->directory_tree($module))) {
			print("removing $dir\n");
			rmdir $dir or warn "could not remove $dir: $!\n";
		}
	}
	
	$self
}

# удаляет пакет и так же из cpanfile
sub del {
	my ($self) = @_;
	
	$self->rm;
	
	my $pkg = $self->first_arg;
	
	$self->cpanfile(sub {
		s/\brequires\s+'\Q$pkg\E'.*\n?//
	});
	
	$self
}

# возвращает пути пакета и его версию
sub find {
	my ($self) = @_;
	$self
}

#@@category утилиты

# выдаёт исключение
sub nonzero_args {
	my $self = shift;
	die "не указан пакет" if !@_;
	$self
}

# установить глобально
sub is_glob {
	my ($self) = @_;
	$self->{opt}->{global}
}

# возвращает из аргументов первый
sub first_arg {
	my ($self) = @_;
	my $arg = $self->{args}->[1];
	die "не указан пакет" if !$arg;
	$arg
}

# выполняет команду
sub sys {
	my ($self, $cmd) = @_;
	
	print "$cmd\n";
	system $cmd;
	
	$self
}

# возвращает cpanfile. Если его нет - undef
# 2-й параметр - строка - записывает
# 2-й параметр функция - передаёт ей в $_ cpanfile, a затем записывает $_ в него
sub cpanfile {
	my ($self, $data) = @_;
	
	if(@_ == 2) {
		if(ref $data) {
			local $_ = $self->cpanfile;
			$data->();
			$data = $_;
		}
	
		open $f, ">", "cpanfile" or die "Попытка записать в cpanfile: $!";
		print $f $data;
		close $f;
		return $self;
	}
	
	open my $f, "<", "cpanfile" or return undef;
	my $x = join "", <$f>;
	close $f;
	$x
}

1;
__END__

=encoding utf-8

=head1 NAME

C<cpm>

**Cpan eXtend packet Manager**

# SYNOPSIS

	cxm команда [options]

C<cpm> может устанавливать проекты из C<git>-репозиториев в интернете, вроде C<github.com>, однако не устанавливает их зависимости.

C<cxm> решает эту проблему: он просто вызывает C<cpm> для каждого из таких зависимостей рекурсивно.

=head1 DESCRIPTION

Примеры:

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

	# Пройтись по исходникам и найти все внешние модули подключённые через C<use> или C<require>
	$ cxm find . > cpanfile

=head1 OPTIONS

=over 4

=item B<--help>

Распечатвает информацию.

=item B<-g>

Выполнить действие над глобальными пакетами.

=back

=head1 LICENSE

Copyright (C) Yaroslav O. Kosmina.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>
