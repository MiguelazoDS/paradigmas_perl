#!/usr/bin/env perl
################################################################################
#										          Sección de módulos															 #
################################################################################

#Módulo que contiene la función get().
use LWP::Simple;
#Módulo que permite interactuar con archivos XLSX.
use Excel::Writer::XLSX;
#Módulo que convierte a utf-8 la información obtenida de la página.
use utf8;
################################################################################
# 													Definición de funciones														 #
################################################################################

#Subrutina que guarda en un arreglo el contenido de la página divido por saltos de línea.
#Recibe una url y una referencia a una arreglo. Guarda el contenido de la página en una
#variable auxiliar, la convierte a utf-8. Luego guarda cada línea en un lugar del arreglo.
sub Obtener{
	my ($url, $array) = @_;
	my $contenido = get($url);
	utf8::encode($contenido);
	@{$array}=split("\n", $contenido);
}

#Arma un enlace a partir de otro cambiandole solo una pequeña parte, necesario cuando se quiere obtener
#por ejemplo cada departamento o localidad.
#Recibe la dirección original, una referencia a una nueva dirección, la parte de la url original que se
#desea cambiar, y la nueva línea.
#Verifica si existe la línea que se desea cambiar en la dirección original, y si existe la cambia
#por la nueva.
sub ArmarEnlace{
	my ($old_url, $new_url, $old_line, $new_line)=@_;
	my $long = length($old_line);
	${$new_url}=$old_url;
	$exist=index ${$new_url}, $old_line;
	if($exist!=-1){
		substr ${$new_url}, $exist, $long, $new_line;
	}
}

#Imprime el valor númerico de cada caracter de una cadena.
#Recibe una cadena y va obteniendo el valor con $i, el tercer argumento representa
#la cantidad de caracteres que se toman de esa subcadena. Con ord() se obtiene el
#valor numérico del caracter.
sub imprimir_int_char {
	for $i (0..length($_[0])-1){
		$char = substr($_[0], $i, 1);
		print "Caracter: $char - Valor: ", ord($char), "\n";
	}
}

#Corrige "error del espacio".
#Recibe una referencia a @lineas, cuenta primera la cantidad de veces que se repiten
#los dos caracters en $lineas[$i] y ejecuta la función ArmarEnlace() para cambiar
#esos dos caracteres por un espacio.
sub Corregir {
	for (my $i = 0; $i < scalar@{$_[0]}; $i++) {
		#Contamos primero la cantidad de veces que se repiten esos dos caracteres.
		my @veces = (${$_[0]}[$i] =~ /$_[1]/g);
		my $cantidad = scalar@veces;
		while ($cantidad > 0) {
			ArmarEnlace(${$_[0]}[$i], \${$_[0]}[$i], $_[1], " ");
			$cantidad--;
		}
	}
}

#Del arreglo de lineas "matchea" con linea y lo almacena en un arreglo.
sub ObtenerVotos{
	my ($lineas, $linea, $votos)=@_;
	my $adentro=0;
	foreach $a(@{$linea}){
		foreach $b(@{$lineas}){
			if($b=~m/\Q$a\E/){
				$adentro=1;
			}
			if($adentro==1){
				if($b=~/\>(\d+.*)\</){
					push(@{$votos},$1);
					$adentro=0;
				}

			}
		}
	}
}

#Los valores en la página están puestos con comas cuando superan el valor 1000, al sumarlos se necesita que estén sin comas.
sub QuitarComa{
	my($votos)=@_;
	foreach $a(@{$votos}){
		ArmarEnlace($a,\$b,",","",1);
		ArmarEnlace($b,\$c,",","",1);
		$a=$c;
	}
}

#Se guarda en un arreglo una sumatoria de votos.
sub Sumatoria{
	my ($votos, $sum_votos)=@_;
	my $i=0;
	while($i< scalar@{$votos}){
		${$sum_votos}[$i]+=${$votos}[$i];
		$i++;
	}
}

#Subrutina que debería guardar en el excel los elementos que se le pasan. NO FUNCIONÓ
sub GuardarInfo{
	my ($titulo,$partidos,$categorias,$sum_votos_cat,$sum_votos_part,$worksheet)=@_;
	$worksheet->write(0, 3, $titulo);

}

################################################################################
#																Programa principal														 #
################################################################################

#Página principal.
$url_prov="http://www.justiciacordoba.gob.ar/jel/ReportesEleccion20150705/Index.html";

#Línea adicional que se agrega a la dirección principal para obtener los enlaces,
#donde "x" -> x=P provincia, x=S+nº departamentos, x=L+nº Localidades.
$completar="Resultados/E20150705_x_CA2_0.htm";

#Corta el contenido de la url por lineas y lo guarda en un arreglo.
Obtener($url_prov,\@lineas);

#Hash con todos los departamentos de la provincia como llaves.
%provincia=();
$provincia{"01|Capital"}=();
$provincia{"02|Calamuchita"}=();
$provincia{"03|Colon"}=();
$provincia{"04|Cruz del Eje"}=();
$provincia{"05|General Roca"}=();
$provincia{"06|General San Martin"}=();
$provincia{"07|Ischilin"}=();
$provincia{"08|Juarez Celman"}=();
$provincia{"09|Marcos Juarez"}=();
$provincia{"10|Minas"}=();
$provincia{"11|Pocho"}=();
$provincia{"12|Punilla"}=();
$provincia{"13|Rio Cuarto"}=();
$provincia{"14|Rio Primero"}=();
$provincia{"15|Rio Seco"}=();
$provincia{"16|Rio Segundo"}=();
$provincia{"17|Roque Saenz Pena"}=();
$provincia{"18|San Alberto"}=();
$provincia{"19|San Javier"}=();
$provincia{"20|San Justo"}=();
$provincia{"21|Santa Maria"}=();
$provincia{"22|Sobremonte"}=();
$provincia{"23|Tercero Arriba"}=();
$provincia{"24|Totoral"}=();
$provincia{"25|Tulumba"}=();
$provincia{"26|Union"}=();

#Se crea un arreglo que contiene una serie de 26 cadenas para obtener todas las localidades de cada departamento,
#i va desde 2 hasta 26, por que i=1 que es capital no tiene localidades interiores.
$cadena="var arrLocalidadesSecc";
$i=2;

while($i<27){
	$aux=$cadena.$i." =";
	$i++;
	push(@temporal, $aux);
}

#En este arreglo se almacenan por cada lugar del arreglo todas las localidades interiores de cada departamento.
foreach $a(@temporal){
	foreach $b(@lineas){
		if($b=~m/\Q$a\E/){
			if($b=~/\((.+)\)/){
				push(@arreglo,$1);
			}
		}
	}
}

#agregamos un "vacío" en el primer lugar del arreglo que representa al departamento Capital.
unshift(@arreglo, "");

#Con cada lugar del arreglo anterior, armo un nuevo arreglo que tiene una localidad por cada lugar.
#Asigno ese arreglo a la correspondiente llave del hash %provincia.
$i=0;
foreach $key(sort keys %provincia){
	@aux=split(",",$arreglo[$i]);
	$provincia{$key}=[@aux];
	$i++;
}

#Armo un "molde" de enlace para acceder a todos los departamentos.
ArmarEnlace($url_prov, \$url_final, "Index.html", $completar);

#Cambio la "x" por una "S" concatenada con el número de departamento (1 al 26).
#Guardo todas las nuevas direcciones en un arreglo.
$i=1;
while($i<27){
	ArmarEnlace($url_final, \$url_total, "x", "S".$i);
	push(@departamentos,$url_total);
	$i++;
}

#Armo un arreglo con los nombres de los partidos que participaron en las elecciones
#y otro donde se guardarán los votos validos, nulos, blancos, totales y cantidad de
#electores por padrón.
push(@partidos,"MOVIMIENTO AL SOCIALISMO");
push(@partidos,"FRENTE PROGRESISTA Y POPULAR");
push(@partidos,"FRENTE DE IZQUIERDA Y DE LOS TRABAJADORES");
push(@partidos,"CORDOBA PODEMOS");
push(@partidos,"UNION POR CORDOBA");
push(@partidos,"JUNTOS POR CORDOBA");
push(@partidos,"MST NUEVA IZQUIERDA");
push(@categorias,"Total de Votos VALIDOS");
push(@categorias,"Total de Votos NULOS");
push(@categorias,"Total de Votos BLANCOS");
push(@categorias,"Total de VOTANTES");
push(@categorias,"Total de ELECTORES EN PADRON");

################################################################################
#													Problema del caracter espacio												 #
################################################################################
#La función ObtenerVotos() no funciona correctamente por que el caracter espacio
#no está representado en utf-8 y a pesar que se convirtió, queda como un caracter
#doble no reconocible.

#Guardamos la información del departamento Capital.
Obtener($departamentos[0],\@lineas);

#Buscamos una línea donde se muestre algún nombre de partido.
print $lineas[67],"\n";

#Definimos una variable que contiene el partido que muestra la línea anterior.
$partido = "MOVIMIENTO AL SOCIALISMO";

#Imprimimos el valor númerico de los caracteres de las cadenas para ver que valor tienen.
$c = "\nValores de la cadena de la página\n\n";
utf8::encode($c);
print $c,"\n";

imprimir_int_char($lineas[67],"\n");

print "\nValores de la cadena del partido.\n\n";

imprimir_int_char($partido);

#########################  				 Solución        #############################

#Definimos una cadena que contenga los caracteres que producen el conflicto.
$error= chr(194).chr(160);

print "\nValores de error.\n\n";

imprimir_int_char($error);

#Corregimos el error en el arreglo líneas.
Corregir(\@lineas,$error);

$c = "\nValores de la cadena de la página\n\n";
utf8::encode($c);
print $c,"\n";

imprimir_int_char($lineas[67],"\n");

################################################################################
# 																		Fin																			 #
################################################################################

=pod
#Por cada nombre de partido me fijo linea por linea hasta encontrar coincidencia, cuando la hay $adentro es 1 y cuando sigue con la siguiente linea
#busca cualquier cantidad de numeros separados hasta por dos "," y lo guardo en el arreglo creado. Ej 1,234,124.
@sum_votos_partidos=();
@sum_votos_categorias=();
@votos_partidos=();
foreach $departamento(@departamentos){
	Obtener($departamento, \@lineas);
	ObtenerVotos(\@lineas,\@partidos,\@votos_partidos);
	QuitarComa(\@votos_partidos);
	Sumatoria(\@votos_partidos, \@sum_votos_partidos);
	ObtenerVotos(\@lineas,\@categorias,\@votos_categorias);
	QuitarComa(\@votos_categorias);
	Sumatoria(\@votos_categorias, \@sum_votos_categorias);
	@votos_partidos=();
	@votos_categorias=();
}

sub ObtenerVotos{
	my ($lineas, $linea, $votos)=@_;
	my $adentro=0;
	foreach $a(@{$linea}){
		foreach $b(@{$lineas}){
			if($b=~m/\Q$a\E/){
				$adentro=1;
			}
			if($adentro==1){
				if($b=~/\>(\d+.*)\</){
					push(@{$votos},$1);
					$adentro=0;
				}

			}
		}
	}
}
=cut
=pod
#Creo un arreglo para 27 páginas (Provincia completa y 26 departamentos).
@worksheets=();
#Nombre del archivo
$workbook = Excel::Writer::XLSX->new ("Elecciones_Cordoba.xlsx");
$i=0;
while($i<27){
	$worksheets[$i] = $workbook->add_worksheet();
	$i++;
}

#&GuardarInfo("PROVINCIA",@partidos,@categorias,@sum_votos_partidos, @sum_votos_categorias,$worksheets[0]);

#En la primer hoja guardo los datos de la votación para la provincia completa.
#-----------------------------------------------------
$worksheets[0]->write(0, 3, "PROVINCIA");
$worksheets[0]->write(2, 0, "PARTIDOS");
$worksheets[0]->write(2, 6, "VOTOS");

$i=0;
foreach $a(@partidos){
	$worksheets[0]->write(4+$i, 0, $a);
	$i++;
}
$i=0;
foreach $a(@sum_votos_partidos){
	$worksheets[0]->write(4+$i, 6, $a);
	$i++;
}
$i=0;
foreach $a(@categorias){
	if($a eq "Total de Votos V"){
		#$a=$a."ALIDOS";
		$worksheets[0]->write(12+$i, 0, $a."ALIDOS");
	}
	else{
		$worksheets[0]->write(12+$i, 0, $a);
	}

	$i++;
}
$i=0;
foreach $a(@sum_votos_categorias){
	$worksheets[0]->write(12+$i, 6, $a);
	$i++;
}

@votos_partidos=();
@votos_categorias=();
ArmarEnlace($url_final, \$url_total, "x", "S1", 1);
Obtener($url_total, \@lineas);
ObtenerVotos(\@lineas,\@partidos,\@votos_partidos);
QuitarComa(\@votos_partidos);
ObtenerVotos(\@lineas,\@categorias,\@votos_categorias);
QuitarComa(\@votos_categorias);

#--------------------------------------------------------------
$worksheets[1]->write(0, 3, "01|Capital");
$worksheets[1]->write(2, 0, "PARTIDOS");
$worksheets[1]->write(2, 6, "VOTOS");

$i=0;
foreach $a(@partidos){
	$worksheets[1]->write(4+$i, 0, $a);
	$i++;
}
$i=0;
foreach $a(@votos_partidos){
	$worksheets[1]->write(4+$i, 6, $a);
	$i++;
}
$i=0;
foreach $a(@categorias){
	if($a eq "Total de Votos V"){
		$worksheets[1]->write(12+$i, 0, $a."ALIDOS");
	}
	else{
		$worksheets[1]->write(12+$i, 0, $a);
	}

	$i++;
}
$i=0;
foreach $a(@votos_categorias){
	$worksheets[1]->write(12+$i, 6, $a);
	$i++;
}
#--------------------------------------------------------------
$indice=2;
@votos_partidos=();
@votos_categorias=();
@sum_votos_partidos=();
@sum_votos_categorias=();
#Guardo el resto de los departamentos en las hojas restantes.
foreach $a(sort keys %provincia){
	print "\n\nDepartamento: ", $a,"\n-------------------------------------------------------\n";
	#Omito departamento capital por que ya está guardado y además no tiene localidades interiores.
	if($a ne "01|Capital"){
		foreach $b(@{$provincia{$a}}){
			if($b=~/\"(\d+)\|\d+\;(.+)\"/){#\w+\s*\w*
				$codigo=$1;
				$nombre_loc=$2;
			}
			$aux="L".$codigo;
			ArmarEnlace($url_final,\$url_total,"x",$aux,1);
			Obtener($url_total,\@lineas);
			ObtenerVotos(\@lineas,\@partidos,\@votos_partidos);
			ObtenerVotos(\@lineas,\@categorias,\@votos_categorias);
			QuitarComa(\@votos_partidos);
			QuitarComa(\@votos_categorias);
			Sumatoria(\@votos_categorias, \@sum_votos_categorias);
			Sumatoria(\@votos_partidos, \@sum_votos_partidos);
			@votos_partidos=();
			@votos_categorias=();
			print "\nGuardando...", $nombre_loc;
		}
#-----------------------------------------------------------------------------------
		$worksheets[$indice]->write(0, 3, $a);
		$worksheets[$indice]->write(2, 0, "PARTIDOS");
		$worksheets[$indice]->write(2, 6, "VOTOS");

		$i=0;
		foreach $c(@partidos){
			$worksheets[$indice]->write(4+$i, 0, $c);
			$i++;
		}
		$i=0;
		foreach $c(@sum_votos_partidos){
			$worksheets[$indice]->write(4+$i, 6, $c);
			$i++;
		}
		$i=0;
		foreach $c(@categorias){
			if($c eq "Total de Votos V"){
				$worksheets[$indice]->write(12+$i, 0, $c."ALIDOS");
			}
			else{
				$worksheets[$indice]->write(12+$i, 0, $c);
			}

			$i++;
		}
		$i=0;
		foreach $c(@sum_votos_categorias){
			$worksheets[$indice]->write(12+$i, 6, $c);
			$i++;
		}
		@sum_votos_partidos=();
		@sum_votos_categorias=();
		$indice++;
#---------------------------------------------------------------------------------------
	}
}

print "\nFinalizado.\n-------------------------------------------------------------";

$workbook->close();
=cut
