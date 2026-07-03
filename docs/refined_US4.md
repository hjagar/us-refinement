## US4: Optimización de Triggers de Activación

**As a** desarrollador que trabaja con agentes de IA
**I want** mejorar y ampliar las condiciones de disparo y activación del skill `us-refinement`
**So that** intervenga de manera automática ante borradores de historias en español, o de forma manual mediante comandos cortos.

### Acceptance criteria

**Scenario 1: Activación automática por estructura de historia en español**
- **Given** que el usuario ingresa un texto en la terminal o chat del agente
- **When** el texto contiene las estructuras clásicas de una historia de usuario en español (ej. "Como [rol]", "Quiero [acción]/Quiero poder", "Para [beneficio]")
- **Then** el agente debe activar automáticamente el skill de refinamiento para estructurar el borrador.

**Scenario 2: Activación manual por comando corto**
- **Given** que el usuario quiere iniciar el refinamiento de forma explícita
- **When** escribe los comandos `/refine` o `/refinar` (seguido opcionalmente del borrador de la historia o número de issue)
- **Then** el agente debe disparar inmediatamente el skill `us-refinement` para procesar la entrada.

**Scenario 3: Activación automática por terminología ágil**
- **Given** que el usuario escribe un mensaje en el chat
- **When** se detectan términos clave como "criterios de aceptación", "acceptance criteria", "INVEST", "ready for dev", "definición de terminado" o "definition of done" en relación a un ticket o requerimiento
- **Then** el agente debe activarse para guiar la definición de los escenarios de aceptación.

### Dependencies
- **None**

### Technical scope
- Backend: Sí (actualizar los metadatos de configuración y disparadores en la cabecera YAML de `SKILL.md` y sus respectivas traducciones en los archivos de portabilidad de agentes).
- Frontend: No.

### Assumptions / pending
- Se asume que el motor del agente de IA soporta la coincidencia por expresiones regulares simples o detección semántica sobre los textos configurados en la descripción del skill.

<!-- [AI-DATA]
id: US4
type: feat
breaking: false
dependencies: []
metadata:
  scope:
    backend: true
    frontend: false
  role: developer
  endpoint: null
  auth: false
  ui: false
scenarios:
  - name: Activación automática por estructura de historia en español
    given: que el usuario ingresa un texto en la terminal o chat del agente
    when: el texto contiene las estructuras clásicas de una historia de usuario en español (ej. Como [rol], Quiero [acción]/Quiero poder, Para [beneficio])
    then: el agente debe activar automáticamente el skill de refinamiento para estructurar el borrador.
  - name: Activación manual por comando corto
    given: que el usuario quiere iniciar el refinamiento de forma explícita
    when: escribe los comandos /refine o /refinar (seguido opcionalmente del borrador de la historia o número de issue)
    then: el agente debe disparar inmediatamente el skill us-refinement para procesar la entrada.
  - name: Activación automática por terminología ágil
    given: que el usuario escribe un mensaje en el chat
    when: se detectan términos clave como criterios de aceptación, acceptance criteria, INVEST, ready for dev, definición de terminado o definition of done en relación a un ticket o requerimiento
    then: el agente debe activarse para guiar la definición de los escenarios de aceptación.
-->
