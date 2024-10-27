# Instrucciones para generar ttW

## Setup
Ejecuta los siguientes comandos siempre que habras una nueva terminal.

```
/cvmfs/cms.cern.ch/cmsset_default.sh
cmssw-cc7 -B /mnt_pool
```

Esto lo que hace es activar una sesión de CentOS7 para poder trabajar siempre con el mismo sistema operativo.
A continuación, hacemos el setup básico para cargar las librerias de CMS. La primera vez que ejecutes esto puede que tarde un poco. 

```
./environment.sh
```

## Instalación de Madgraph5_aMC@NLO
Este paso solo tienes que ejecutarlo una vez:

```
./installMG.sh
```

## Lanzar un gridpack
Para lanzar un gridpack, asumiendo que tienes tus `cards` en la carpeta `cards/mi_proceso`, y esas cards tienen el siguiente formato de nombre: `mi_proceso_*.dat`, simplemente ejecuta:
 
```
./gridpack_generation.sh mi_proceso cards/mi_proceso
```

## Ejemplo: ttW
```
./gridpack_generation.sh TTLNu-1Jets_NLO_FXFX cards/ttW-TFG
```

Esto empezará a correr el código necesario para crear el gridpack de ttW que se desea.