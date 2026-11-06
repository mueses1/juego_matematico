# Juego Matematico con tematica de grado noveno grado de secundaria— Edición Dragón

Juego educativo hecho con Godot 4.3+ (funciona en 4.x).

## Cómo abrirlo
1. Abre Godot 4 -> Importar -> selecciona `project.godot`.
2. Pulsa F5 para jugar.

## Reglas
- La ruleta decide el nivel inicial de las preguntas: Básico, Medio o Superior.
- Cada respuesta correcta alegra al dragón, lo hace crecer y sube la dificultad.
- Las etapas del dragón son: Bebé -> Cría -> Joven -> Adulto -> Legendario.
- Cada error entristece al dragón: Feliz -> Preocupado -> Triste -> Muy triste.
- Los errores no reducen la etapa del dragón; al volver a acertar recupera la alegría.
- Ganas cuando el dragón llega a la etapa Legendario (4 aciertos).

## Banco de preguntas
El juego trae **63 preguntas** (20 de nivel Básico, 20 de Medio y 23 de Superior)
basadas en los DBA de Matemáticas de grado 9 del MEN, los Estándares Básicos de
Competencias y la malla curricular de noveno.

Contenidos trabajados:
- Números reales: notación científica, valor absoluto, potencias y radicales.
- Álgebra: productos notables, factorización, ecuaciones e inecuaciones lineales
  y cuadráticas, sistemas 2x2 y regla de Cramer, números complejos.
- Funciones: lineal, afín, cuadrática (vértice, máximos y mínimos), inversa,
  exponencial y logarítmica.
- Geometría y medida: Pitágoras, Tales, semejanza, circunferencia, áreas y
  volúmenes de prismas, cilindros y esferas.
- Estadística y probabilidad: media, mediana, diagramas de caja, combinaciones,
  permutaciones y probabilidad de eventos compuestos.
- Sucesiones y matemáticas financieras: sucesiones aritméticas y geométricas,
  interés simple y compuesto.

## Agregar preguntas
Edita `questions.gd`. En cada pregunta, la PRIMERA opción de "o" es la correcta
(el juego las mezcla al mostrarlas). Cada pregunta debe tener exactamente
4 opciones diferentes y una explicación en "e".

## Personalizar al dragón
El dibujo, las animaciones y los estados de ánimo están en `dragon.gd`.
Las etapas (`MAX_STAGE`) y los niveles de tristeza (`MAX_SADNESS`) se pueden
ajustar al inicio de ese archivo.
