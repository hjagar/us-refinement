## US8: Análisis de Impacto y Viabilidad Técnica en Refinamiento (Feasibility & High-Level Impact Analysis)

**As a** desarrollador o analista técnico
**I want** que el skill realice una inspección superficial del entorno y estructura del codebase durante el análisis INVEST
**So that** pueda alertar tempranamente sobre dependencias técnicas faltantes o riesgos de acoplamiento sin detallar la implementación en la historia de usuario.

### Acceptance criteria

**Scenario 1: Detección de herramientas del entorno requeridas**
- **Given** que la historia de usuario cruda menciona explícitamente el uso de una herramienta o entorno (ej. "Docker", "Python", "CLI")
- **When** el skill se ejecuta y detecta que la herramienta no está instalada en el PATH o no figura en la configuración del repositorio
- **Then** el skill debe agregar una advertencia en la sección de dependencias o suposiciones ("Assumptions / pending") para alertar sobre la dependencia técnica faltante.

**Scenario 2: Detección de posibles colisiones o ambigüedad en componentes**
- **Given** que la historia de usuario cruda menciona modificar un componente funcional existente (ej. "el instalador")
- **When** el skill busca de forma superficial archivos que coincidan con ese nombre y encuentra múltiples coincidencias o ninguna
- **Then** debe alertar al usuario en el paso de clarificación (Step 2) sobre la ambigüedad encontrada para acotar el alcance de la historia de usuario antes de finalizar.

**Scenario 3: Preservar la separación de incumbencias (no proponer el "Cómo")**
- **Given** que el skill ejecuta los chequeos de entorno y código durante el análisis
- **When** genera el markdown final refinado con los criterios de aceptación
- **Then** no debe proponer líneas de código, firmas de funciones, arquitecturas ni rutas de archivos específicos de implementación, manteniéndose exclusivamente a nivel del "Qué" y "Por qué" del negocio.

### Dependencies
- **US2: Autodetección de Entorno y Herramientas**

### Technical scope
- Backend: Sí (lógica de escaneo en la ejecución del skill `us-refinement`).
- Frontend: No.

### Assumptions / pending
- Se asume que el chequeo de archivos se realiza a nivel de listado de directorios y nombres de archivos sin analizar semánticamente el código interno, para evitar lentitud y consumo excesivo de tokens.

<!-- [AI-DATA]
id: US8
type: feat
breaking: false
dependencies: [US2]
metadata:
  scope:
    backend: true
    frontend: false
  role: "developer"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Detect required environment tools"
    given: "the raw user story mentions a specific tool or environment"
    when: "the tool is missing from the system PATH or repository configuration"
    then: "it adds a warning in the dependencies or assumptions section to raise awareness"
  - name: "Detect component ambiguity or collisions"
    given: "the raw user story mentions modifying an existing component"
    when: "the skill performs a quick search and finds multiple or zero file matches"
    then: "it raises a clarification question in Step 2 to narrow down the scope"
  - name: "Preserve separation of concerns"
    given: "the skill runs high-level code and environment checks"
    when: "the final refined markdown is generated"
    then: "it does not propose implementation code, signatures, or specific paths, keeping it strictly at the what and why level"
-->
