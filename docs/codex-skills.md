# Codex Skills

Un skill es un contrato operativo para la IA: define cuándo se activa, qué reglas debe seguir y qué salida debe devolver. No es documentación larga para humanos; es una guía ejecutable para que el agente trabaje con disciplina.

## Idea principal

Los skills sirven cuando hay un patrón repetido, una convención del proyecto o un workflow que querés que Codex ejecute siempre igual.

No conviene crear un skill para algo trivial o de una sola vez. Ahí alcanza con una instrucción normal o documentación común.

## Cómo los maneja Codex

Antes de responder o actuar, el agente debería hacer este chequeo:

1. Revisar si el pedido activa algún skill disponible.
2. Leer el `SKILL.md` completo del skill que matchea.
3. Seguir sus reglas antes de tocar código, escribir documentación o responder.
4. Leer referencias o assets solo si el `SKILL.md` lo exige.
5. Aplicar el contrato de salida definido por el skill.

La regla importante: el skill manda. No se improvisa el proceso si ya existe una instrucción específica.

## Cuándo crear un skill

Creá un skill cuando necesitás que la IA repita un comportamiento con límites claros:

- workflows complejos;
- convenciones propias del proyecto;
- reglas de arquitectura o testing;
- generación de artefactos con formato estable;
- coordinación entre agentes;
- decisiones repetibles con criterios explícitos.

No lo crees solo porque “suena potente”. Eso termina en más complejidad, más tokens y menos control.

## Estructura recomendada

```text
skills/mi-skill/
└── SKILL.md
```

Frontmatter mínimo:

```yaml
---
name: mi-skill
description: "Trigger: palabras clave. Qué hace este skill."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---
```

Cuerpo sugerido:

```md
## Activation Contract
Usá este skill cuando...

## Hard Rules
- Hacé esto.
- No hagas esto.

## Decision Gates
| Situación | Acción |
|-----------|--------|
| ... | ... |

## Execution Steps
1. Revisá...
2. Aplicá...
3. Devolvé...

## Output Contract
Respondé con...
```

## Opinión sobre un skill multi-agente

Tiene sentido crear un skill multi-agente si hay delegación real. No alcanza con “varios agentes colaborando”; eso es humo si no hay bordes claros.

El diseño sano es:

```text
orquestador -> ejecutores especializados -> verificador
```

El orquestador coordina. Los ejecutores hacen trabajo acotado. El verificador revisa contra el contrato.

## Qué debería definir un skill multi-agente

Un buen skill multi-agente debería dejar explícito:

- cuándo delegar y cuándo resolver inline;
- qué contexto recibe cada sub-agente;
- qué permisos tiene cada sub-agente;
- qué formato debe devolver cada uno;
- qué se guarda en memoria persistente;
- quién decide, quién ejecuta y quién verifica;
- cuándo se detiene para pedir input humano.

Contrato de salida recomendado para sub-agentes:

```yaml
status: success | partial | blocked | failed
findings:
  - ...
changes:
  - ...
risks:
  - ...
next_steps:
  - ...
```

## Riesgo principal

El riesgo de un skill multi-agente es convertir disciplina en caos distribuido.

Si cada agente puede leer todo, decidir todo y escribir todo, no tenés arquitectura: tenés ruido con más procesos. Multi-agente sirve cuando separás responsabilidades de verdad: explorar, diseñar, implementar y verificar.

## Regla arquitectónica

Diseñá skills como sistemas con límites claros.

La IA es una herramienta. El humano lidera. El skill existe para reducir improvisación, no para esconder decisiones importantes detrás de automatización.
