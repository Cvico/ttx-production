# Instrucciones básicas para correr Madgraph5_aMC@NLO
En primer lugar, deberías seguir los pasos del README.md de la carpeta principal para instalar Madgraph v3.5.6.

## Introducción
En este tutorial, vamos a intentar analizar cómo se ejecuta Madgraph. Para ello, vamos a centrarnos en cómo se corren los procesos de Madgraph5_aMC@NLO. Para cualquier duda, la mejor referencia es la [página oficial de madgraph](https://launchpad.net/mg5amcnlo).

## El concepto de `card`.
En HEP, una `card` suele ser el argot que utilizamos para especificar ficheros de configuración. En el caso de `madgraph`, las `cards` configuran:

1. El proceso que queremos generar (`proc_card.dat`)
2. La física de los objetos en este proceso (`run_card.dat`)
3. Los parámetros del modelo estándar (`param_card.dat`)
4. Otras cards se utilizan para activar diferentes funcionalidades de `madgraph` (ejemplo: `madspin_card.dat`). **No vamos a cubrir este último caso en detalle**. 


## El tutorial
En este tutorial vamos a coger un proceso simple como puede ser ttW y estudiar los diagramas de Feynman que intervienen. Para ello, creamos un fichero `proc_card.dat` que contenga el siguiente contenido:

```
import model loop_sm-no_b_mass

define ell+ = e+ mu+ ta+
define ell- = e- mu- ta-
define vll = ve vm vt
define vll~ = ve~ vm~ vt~

generate p p > t t~ ell+ vll [QCD]
add process p p > t t~ ell+ vll j [QCD]
add process p p > t t~ ell- vll~ [QCD] 
add process p p > t t~ ell- vll~ j [QCD]

output TTLNu-1Jets_amcatnloFXFX-pythia8
```

La `card` se lee de la siguiente manera:

`import model loop_sm-no_b_mass`. Esta línea especifica el modelo de `madgraph` que estamos utilizando: `loop_sm`. En este caso, `sm` indica que es _Standard Model_, mientras que `loop` indica que incluye correcciones de `loops`, es decir, que incluye cálculos a next-to-leading order (NLO) en la expansión de QCD.

```
define ell+ = e+ mu+ ta+
define ell- = e- mu- ta-
define vll = ve vm vt
define vll~ = ve~ vm~ vt~
```

Estas lineas define la `multiparticle ell` y `vll`, con el objetivo único de simplificar la sintáxis de la card. En lugar de tener que hacer varias lineas por cada sabor de leptón, uno puede simplemente escribir `ell` y `vll`, y de esta manera reducir el tamaño de la card.


```
generate p p > t t~ ell+ vll [QCD] 
add process p p > t t~ ell+ vll j [QCD]
add process p p > t t~ ell- vll~ [QCD]
add process p p > t t~ ell- vll~ j [QCD] 
```
Estas lineas definen el proceso a generar. En este caso, el proceso inicial y final se distinguen mediante el símbolo `>`. El estado inicial siempre es `proton-protón` (pues son colisiones del LHC), y el estado final siempre incluye `t t~ + algo`. La `t` indica generación de un quark top, mientras que `t~` implica la generación de un antitop quark. El `algo` es lo que caracteriza a esta generación. En este caso, el objetivo es generar eventos con un par top-antitop (`t t~`), además de un leptón (`ell`) y un neutrino (`vll`), de cualquier sabor. 

La palabra `[QCD]` le indica a `madgraph`que esta es una generación a NLO, y son los encargados de añadir **radiaciones virtuales**. La primera y segunda linea indican, por tanto la generación de: ttW+, con W+ desintegrandose en un leptón y un neutrino, a LO (primera linea) y NLO (pues está el `[QCD]`); incluyendo también hasta una **radiación real** (segunda linea, que es igual que la primera, pero incluyendo un `j` al final, que indica la radiación real que se incluye).

Finalmente: `output TTLNu-1Jets_amcatnloFXFX-pythia8` le indica a madgraph la carpeta en la que se quiere guardar el `output`.

## Generar diagramas de feynman para este proceso
Para ello, ejecuta los siguientes comandos (importante haber hecho el setup que se indica en la carpeta principal).

```
run_mg proc_card.dat
```

## Preguntas
- ¿Sabrías describir en pocas palabras lo que está haciendo `madgraph` cuando ejecutas ese comando?
- No hemos dado como input ninguna `run_card` ni `param_card`. Esto implica que Madgraph está utilizando las que tiene por defecto. ¿Sabrías encontrar dentro de la carpeta `TTLNu-1Jets_amcatnloFXFX-pythia8` la `run_card` y la `param_card` que usa madgraph por defecto?.
- Echale un vistazo a los diagramas de feynman que se generan. Para eso ejecuta el siguiente script: `./convert_ps_to_pdf.sh  TTLNu-1Jets_amcatnloFXFX-pythia8`.
- Lo más importante: pregunta cualquier duda que tengas! 
