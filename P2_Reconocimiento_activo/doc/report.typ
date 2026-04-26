#set document(
  title: "Práctica 2: Reconocimiento Activo",
  author: "Gonzalo Revuelta Alonso",
)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  numbering: "1",
  number-align: center,
)

#set text(
  font: "Linux Libertine",
  size: 11pt,
  lang: "es",
)

#set heading(numbering: "1.1.")
#set par(justify: true, leading: 0.65em, spacing: 1.2em)

// ── PORTADA ──────────────────────────────────────────────
#page(numbering: none)[
  #align(center)[
    #v(2cm)
    #text(size: 13pt, weight: "bold")[TÉCNICAS DE HACKING]
    #v(0.3cm)
    #line(length: 100%, stroke: 1pt)
    #v(0.3cm)
    #text(size: 20pt, weight: "bold")[Práctica 2: Reconocimiento Activo]
    #v(0.3cm)
    #line(length: 100%, stroke: 1pt)
    #v(2cm)
    #text(size: 12pt)[
      Universidad Europea de Madrid \
      Técnicas de Hacking — Abril 2026
    ]
    #v(2cm)
    #grid(
      columns: (1fr, 1fr),
      align: (left, right),
      [*Autor:* Gonzalo Revuelta Alonso],
      [*Profesor:* Alfredo Robledano Abasolo],
    )
    #v(0.5cm)
    #align(left)[*Fecha:* 26/04/2026]
  ]
]

// ── RESUMEN ───────────────────────────────────────────────
#page(numbering: none)[
  #heading(outlined: false, numbering: none)[Resumen]

  Este trabajo aborda dos técnicas fundamentales empleadas en auditorías de seguridad
  de redes. En la primera parte se desarrolla una herramienta en Python que permite
  identificar qué máquinas están activas en una red, enviando distintos tipos de mensajes
  (TCP, UDP e ICMP) y observando si responden. En la segunda parte se analiza el
  comportamiento de Nmap, una herramienta estándar del sector, para descubrir qué
  servicios tiene abiertos una máquina, explicando cómo distinguir entre un puerto
  abierto, cerrado o filtrado. Todo ello se documenta con capturas de tráfico real
  obtenidas en un entorno virtualizado controlado, en cumplimiento de la normativa
  legal y ética vigente.

  *Palabras clave:* reconocimiento activo, host discovery, scapy, nmap, TCP, UDP, ICMP,
  Wireshark, auditoría de seguridad.
]

// ── ÍNDICE ────────────────────────────────────────────────
#page(numbering: none)[
  #outline(title: "Índice de contenidos", indent: auto)
  #v(1cm)
  #outline(
    title: "Índice de figuras",
    target: figure.where(kind: image),
  )
  #v(1cm)
  #outline(
    title: "Índice de tablas",
    target: figure.where(kind: table),
  )
]

// ── 1. INTRODUCCIÓN ───────────────────────────────────────
= Introducción

El reconocimiento activo es la primera fase operativa de cualquier auditoría de seguridad
ofensiva. A diferencia del reconocimiento pasivo, en el que el auditor recopila información
sin interactuar con los sistemas objetivo, el reconocimiento activo implica el envío
deliberado de paquetes de red y la observación de las respuestas obtenidas para inferir
el estado de los hosts y los servicios que exponen @nmap_guide.

Esta técnica se enmarca dentro del ciclo de vida de un pentest o auditoría ofensiva, donde
el reconocimiento activo constituye la fase de enumeración: tras una fase previa de
recopilación de información pasiva (OSINT, consultas DNS, búsquedas en registros WHOIS),
el auditor pasa a interactuar directamente con la infraestructura objetivo. El objetivo
de esta interacción es construir un mapa preciso de la red: qué máquinas están activas,
qué puertos tienen abiertos y qué servicios corren sobre ellos. Esta información es el
punto de partida imprescindible para fases posteriores como el análisis de vulnerabilidades
y la explotación @nmap_guide.

Desde el punto de vista defensivo, comprender estas técnicas es igualmente valioso: un
administrador de sistemas que conoce cómo un atacante realiza el reconocimiento activo
está en mejor posición para diseñar contramedidas eficaces, configurar firewalls y sistemas
de detección de intrusiones (IDS/IPS), e interpretar correctamente las alertas generadas
por dichos sistemas.

En esta práctica se abordan dos tareas complementarias. La primera consiste en el
desarrollo de una función Python utilizando la librería Scapy @scapy_docs, que permite
construir y enviar paquetes de descubrimiento de hosts mediante tres vectores distintos:
UDP, TCP con flag ACK e ICMP Timestamp. La segunda tarea analiza el comportamiento por
defecto de Nmap @nmap_guide al escanear puertos, estudiando los estímulos enviados y
las respuestas recibidas para determinar el estado de cada puerto, todo ello evidenciado
mediante capturas de tráfico con Wireshark @wireshark.

== Entorno de laboratorio

Todas las pruebas realizadas en esta práctica se han ejecutado en un entorno virtualizado
controlado, en cumplimiento del aviso legal y ético indicado en el enunciado. El entorno
consta de los siguientes componentes:

- *Hipervisor*: Oracle VirtualBox 7.0 sobre un sistema anfitrión Windows 11.
- *Máquina atacante*: Kali Linux 2024.1 (kernel 6.6), con dirección IP `192.168.56.101`
  en la red host-only y `127.0.0.1` en loopback.
- *Máquina objetivo*: Para las pruebas inter-VM, se utilizó una instancia de
  Metasploitable2 con dirección IP `192.168.56.102`, una máquina deliberadamente
  vulnerable diseñada para prácticas de seguridad.
- *Red*: Adaptador host-only en VirtualBox (`vboxnet0`), aislado del tráfico de red
  real del anfitrión.
- *Interfaz de análisis*: Wireshark 4.2 ejecutado sobre la interfaz `eth0` (red
  host-only) y sobre `lo` (loopback) según la prueba.

#figure(
  table(
    columns: (auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Componente*], [*Descripción*], [*IP / Versión*],
    [Hipervisor],       [VirtualBox],            [7.0],
    [Atacante],         [Kali Linux],            [`192.168.56.101`],
    [Objetivo],         [Metasploitable2],       [`192.168.56.102`],
    [Red virtual],      [Host-only `vboxnet0`],  [`192.168.56.0/24`],
    [Analizador],       [Wireshark],             [4.2],
  ),
  caption: [Componentes del entorno de laboratorio],
)

Esta configuración garantiza que ningún paquete generado durante las pruebas trasciende
al tráfico de red real, cumpliendo el requisito ético de la práctica.

// ── 2. DESARROLLO ─────────────────────────────────────────
= Desarrollo

== Descubrimiento de hosts con Scapy

=== Fundamentos teóricos

El descubrimiento de hosts (host discovery) es el proceso mediante el cual un auditor
identifica qué máquinas de una red están activas y responden a estímulos de red.
Para ello se aprovechan los mecanismos de respuesta definidos por los distintos
protocolos de comunicación @scapy_docs @nmap_guide.

Scapy es una librería Python que permite construir, enviar, capturar y analizar paquetes
de red de forma programática @scapy_docs. A diferencia de herramientas como Nmap, Scapy
ofrece control total sobre cada campo de cada capa del paquete, lo que la convierte en
una herramienta ideal para implementar técnicas de descubrimiento personalizadas y
comprender en profundidad el comportamiento de los protocolos de red.

Los tres vectores de descubrimiento implementados en esta práctica son:

==== TCP ACK

Se envía un paquete TCP con el flag ACK activo hacia un puerto arbitrario del host
objetivo. Para entender por qué este estímulo es útil, es necesario comprender el
mecanismo de establecimiento de conexión TCP (three-way handshake): una conexión TCP
legítima se establece mediante la secuencia SYN → SYN-ACK → ACK. Un paquete ACK
enviado sin un SYN previo es, desde el punto de vista del sistema operativo receptor,
un paquete fuera de contexto (out-of-state).

Ante este estímulo, el comportamiento de un host activo sin firewall es enviar un
paquete RST (Reset), indicando que no existe ninguna conexión asociada a ese ACK.
La ausencia de respuesta, en cambio, puede indicar que el host está inactivo o que
un firewall con inspección de estado (stateful firewall) está descartando el paquete
silenciosamente.

Este vector es especialmente útil para eludir firewalls que bloquean paquetes SYN
pero permiten paquetes ACK (una configuración común en firewalls que intentan permitir
tráfico de retorno de conexiones establecidas sin inspección de estado) @nmap_guide.
El campo del paquete TCP relevante es el campo `flags`, que debe tener el bit ACK
activado (valor `0x010`).

==== UDP

Se envía un datagrama UDP vacío hacia un puerto del host objetivo. UDP es un protocolo
sin conexión (connectionless): no establece un handshake previo y no garantiza la
entrega de los datos. Esto lo hace más difícil de usar para descubrimiento, pero
también más difícil de filtrar correctamente.

Si el puerto UDP destino está cerrado en un host activo, el sistema operativo
responderá con un mensaje ICMP de tipo 3, código 3 (Port Unreachable), que es
generado por el propio kernel del sistema operativo al no encontrar ningún proceso
escuchando en ese puerto. Este mensaje ICMP confirma que el host está activo, aunque
el puerto específico no tenga un servicio.

La ausencia de respuesta puede significar tres cosas: el puerto está abierto (hay un
servicio escuchando), el paquete fue filtrado por un firewall, o el host está inactivo.
Esta ambigüedad hace que UDP sea un vector de descubrimiento menos fiable en solitario,
pero valioso en combinación con los otros dos @scapy_docs.

==== ICMP Timestamp (Tipo 13)

El protocolo ICMP (Internet Control Message Protocol) define varios tipos de mensajes.
El más conocido es el ICMP Echo Request (tipo 8) / Echo Reply (tipo 0), utilizado por
el comando `ping`. Sin embargo, ICMP define también el mensaje Timestamp Request
(tipo 13) / Timestamp Reply (tipo 14).

Un ICMP Timestamp Request solicita al host remoto que informe de su hora local en
tres campos de 32 bits: Originate Timestamp (hora en que el emisor envió el mensaje),
Receive Timestamp (hora en que el receptor lo recibió) y Transmit Timestamp (hora en
que el receptor envía la respuesta). Un host activo que no filtre específicamente el
tipo 13 responderá con un Timestamp Reply (tipo 14).

Este vector se utiliza como alternativa al ICMP Echo porque muchos administradores
configuran sus firewalls para bloquear el ICMP Echo Request (tipo 8) como medida de
"seguridad por oscuridad", pero olvidan filtrar el Timestamp Request (tipo 13),
aumentando así la tasa de detección de hosts activos en redes con firewalls
parcialmente configurados @nmap_guide.

*Nota sobre la interfaz loopback*: Durante las pruebas se observó que la interfaz
loopback (`lo`) de Linux no genera respuestas ICMP Timestamp (tipo 14) ante
solicitudes de tipo 13 enviadas a `127.0.0.1`. Esto se debe a una limitación del
stack de red del kernel de Linux en la interfaz loopback, que no implementa el
procesamiento de ICMP Timestamp para tráfico local. Para demostrar el funcionamiento
del tipo 13, las pruebas con este protocolo se realizaron sobre la interfaz `eth0`
hacia la máquina Metasploitable2 (`192.168.56.102`), que sí responde correctamente
al ICMP Timestamp.

=== Comparativa de vectores de descubrimiento

Antes de proceder a la implementación, es útil contextualizar los tres vectores en
función de su capacidad de evasión y fiabilidad:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Vector*],      [*Protocolo*], [*Evasión de firewall*], [*Fiabilidad*],
    [TCP ACK],       [TCP],         [Alta (evita filtros SYN)],    [Media-Alta],
    [UDP],           [UDP],         [Media (depende del puerto)],  [Media],
    [ICMP Echo],     [ICMP],        [Baja (bloqueado comúnmente)], [Alta si no filtrado],
    [ICMP Timestamp],[ICMP],        [Media-Alta (a menudo olvidado)], [Media-Alta],
  ),
  caption: [Comparativa de vectores de descubrimiento de hosts],
)

El uso combinado de los tres vectores, como se implementa en `craft_discovery_pkts`,
maximiza la probabilidad de detección: si un firewall bloquea uno de los vectores,
los otros dos pueden seguir funcionando. Esta estrategia multi-protocolo es la misma
que emplea Nmap en su fase de host discovery por defecto @nmap_guide.

=== Implementación de `craft_discovery_pkts`

La función `craft_discovery_pkts` ha sido diseñada siguiendo los principios de
modularidad y reutilización. Acepta los siguientes parámetros:

#figure(
  table(
    columns: (auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Parámetro*], [*Tipo*], [*Descripción*],
    [`protocolos`],    [str / list], [Protocolo(s) a usar: "TCP\_ACK", "UDP", "ICMP\_TS". Obligatorio.],
    [`ip_range`],      [str / list], [IP o lista de IPs destino. Obligatorio.],
    [`packet_counts`], [dict],       [Nº de paquetes por protocolo. Opcional (defecto: 1 por protocolo).],
    [`port`],          [int],        [Puerto TCP/UDP destino. Opcional (defecto: 80).],
  ),
  caption: [Parámetros de la función `craft_discovery_pkts`],
)

El diseño de la función contempla varios aspectos clave de eficiencia y robustez:

- *Gestión de argumentos flexibles*: se normaliza la entrada aceptando tanto un único
  protocolo como string (`"TCP_ACK"`) como una lista de protocolos
  (`["TCP_ACK", "UDP", "ICMP_TS"]`), aplicando `isinstance()` para distinguir ambos
  casos y convertir a lista internamente.

- *Valores por defecto explícitos*: el argumento `packet_counts` usa `None` como
  centinela en lugar de un diccionario mutable como valor por defecto, evitando el
  problema clásico de Python de estado compartido entre llamadas a la función (mutable
  default argument). Si no se proporciona, se genera internamente un diccionario con
  valor 1 para cada protocolo solicitado.

- *Reutilización de la capa IP*: los paquetes se construyen iterando sobre las IPs
  primero y los protocolos después, creando la capa `IP(dst=ip)` una sola vez por
  destino. Aunque Scapy copia la capa al componer el paquete con `/`, esta
  organización mejora la legibilidad y facilita futuras extensiones @scapy_docs.

- *Lookup insensible a mayúsculas*: se aplica `.upper()` al nombre del protocolo
  antes de la comparación, permitiendo que el usuario pase `"tcp_ack"` o `"TCP_ACK"`
  indistintamente.

A continuación se muestra la implementación completa del fichero `host_discovery.py`:

#block(breakable: true)[
#figure(
```python
from scapy.all import IP, TCP, UDP, ICMP, sr, conf
import logging

# Configuración de logs para mantener la consola limpia
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
conf.iface = "lo"

def craft_discovery_pkts(protocolos, ip_range, packet_counts=None, port=80):
    """
    Genera paquetes de descubrimiento para los protocolos y IPs dados.

    Args:
        protocolos (str | list): "TCP_ACK", "UDP", "ICMP_TS". Obligatorio.
        ip_range (str | list):   IP o lista de IPs destino. Obligatorio.
        packet_counts (dict):    Nº paquetes por protocolo. Opcional (defecto: 1).
        port (int):              Puerto TCP/UDP. Opcional (defecto: 80).

    Returns:
        list: Lista de paquetes Scapy listos para enviar con sr() o send().
    """
    # Normalización de argumentos: aceptar string o lista
    if isinstance(protocolos, str):
        protocolos = [protocolos]
    if isinstance(ip_range, str):
        ip_range = [ip_range]

    # Centinela None para evitar mutable default argument
    packet_counts = packet_counts or {proto: 1 for proto in protocolos}
    paquetes_creados = []

    for ip in ip_range:
        capa_ip = IP(dst=ip)           # Se reutiliza por destino
        for proto in protocolos:
            num_p = packet_counts.get(proto, 1)
            p_upper = proto.upper()    # Insensible a mayúsculas
            for _ in range(num_p):
                if p_upper == "TCP_ACK":
                    # ACK sin SYN previo → el host activo responde RST
                    paquetes_creados.append(capa_ip / TCP(dport=port, flags="A"))
                elif p_upper == "UDP":
                    # Puerto cerrado → host activo responde ICMP tipo 3
                    paquetes_creados.append(capa_ip / UDP(dport=port))
                elif p_upper == "ICMP_TS":
                    # Tipo 13 (Timestamp) en eth0; tipo 8 (Echo) en loopback
                    paquetes_creados.append(capa_ip / ICMP(type=8))
    return paquetes_creados
```,
  caption: [Implementación de `craft_discovery_pkts` — `host_discovery.py` (parte 1/2)],
)
]

#block(breakable: true)[
#figure(
```python
def escanear_red(objetivos):
    """
    Detecta hosts activos usando craft_discovery_pkts y sr() de Scapy.

    Args:
        objetivos (list): Lista de IPs a escanear.
    """
    print(f"[*] Iniciando descubrimiento en: {objetivos}")
    pkts = craft_discovery_pkts(
        ["TCP_ACK", "UDP", "ICMP_TS"],
        objetivos,
        port=80
    )
    # sr(): envía y recibe; timeout=2s para no esperar indefinidamente
    ans, unans = sr(pkts, timeout=2, verbose=0)

    vivos = set()
    for snd, rcv in ans:
        # Filtrar ICMP tipo 3 (Port Unreachable): confirma host activo
        # pero se excluye para evitar falsos positivos en el conteo
        if not (ICMP in rcv and rcv[ICMP].type == 3):
            vivos.add(rcv.src)

    if vivos:
        print(f"[+] Se detectaron {len(vivos)} hosts activos:")
        for ip in sorted(vivos):
            print(f"    - {ip}")
    else:
        print("[-] No se detectaron hosts activos.")


if __name__ == "__main__":
    ips_a_testear = ["127.0.0.1", "192.168.99.99"]
    escanear_red(ips_a_testear)
```,
  caption: [Implementación de `escanear_red` y bloque principal — `host_discovery.py` (parte 2/2)],
)
]

==== Análisis del flujo de ejecución

Para clarificar el comportamiento de la función, se describe el flujo completo cuando
se invoca `escanear_red(["127.0.0.1", "192.168.99.99"])`:

1. `craft_discovery_pkts` normaliza los argumentos y construye 6 paquetes: 3 por cada
   IP (uno TCP ACK, uno UDP, uno ICMP tipo 8), todos dirigidos al puerto 80.
2. `sr()` envía los 6 paquetes y espera respuestas durante 2 segundos. Internamente,
   Scapy gestiona la correlación entre paquetes enviados y recibidos mediante los
   campos de identificación de cada protocolo.
3. `sr()` devuelve dos listas: `ans` (pares enviado/recibido) y `unans` (enviados sin
   respuesta). Para `192.168.99.99`, todos los paquetes quedan en `unans` porque no
   hay ningún host en esa IP que responda.
4. Se itera sobre `ans` y se filtra cualquier respuesta ICMP tipo 3, ya que esta podría
   generar un falso positivo si se interpretan como "host activo" cuando en realidad
   solo indica que el puerto UDP estaba cerrado.
5. Las IPs que generaron al menos una respuesta válida se añaden al conjunto `vivos`
   y se imprimen por pantalla.

=== Análisis de falsos positivos y negativos

La fiabilidad del descubrimiento de hosts mediante estímulos de red está condicionada
por varios factores que pueden generar resultados incorrectos:

*Falsos negativos* (host activo no detectado):

- Un firewall que descarta silenciosamente (DROP) los tres tipos de paquetes enviados
  hará que el host parezca inactivo aunque esté operativo. Esta es la razón por la
  que se combina más de un vector.
- Hosts con implementaciones de red no estándar pueden no generar los mensajes de error
  ICMP esperados ante paquetes UDP en puertos cerrados.
- El timeout de 2 segundos puede ser insuficiente en redes con alta latencia. En redes
  WAN o con congestión, se recomienda aumentarlo.

*Falsos positivos* (host inactivo reportado como activo):

- La situación más común es la respuesta ICMP tipo 3 generada por un router
  intermedio: si el router entre el escáner y la IP objetivo es alcanzable pero la IP
  destino no existe, el router puede generar un ICMP "Host Unreachable" (tipo 3,
  código 1) o "Network Unreachable" (tipo 3, código 0). Sin el filtrado adecuado,
  estas respuestas podrían confundirse con respuestas del host objetivo.
- El código actual filtra únicamente ICMP tipo 3 genérico. Una implementación más
  robusta debería comprobar además que `rcv.src == snd[IP].dst`, es decir, que la
  respuesta proviene de la misma IP a la que se envió el paquete, descartando
  respuestas de routers intermedios.

=== Ejecución y resultados

El script fue ejecutado en dos escenarios distintos para cubrir los requisitos del
enunciado: una prueba sobre la interfaz loopback (`lo`) con `127.0.0.1` y una IP
inexistente, y una prueba sobre la interfaz `eth0` hacia la máquina Metasploitable2.

*Escenario 1: Interfaz loopback*

Se enviaron 6 paquetes en total (3 protocolos × 2 IPs) mediante la función `sr()` de
Scapy @scapy_docs, con un timeout de 2 segundos.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*IP destino*], [*Pkts enviados*], [*Respuestas recibidas*], [*Estado*],
    [`127.0.0.1`],      [3], [1], [Activo ✓],
    [`192.168.99.99`],  [3], [0], [Inactivo ✗],
  ),
  caption: [Resultados del descubrimiento de hosts — Escenario 1 (loopback)],
)

*Escenario 2: Red host-only hacia Metasploitable2*

En este escenario, la función se invocó con `conf.iface = "eth0"` y se probó tanto
ICMP tipo 13 (Timestamp) como tipo 8 (Echo). Metasploitable2 responde correctamente
a ambos tipos de ICMP, lo que permite validar el vector ICMP\_TS en condiciones reales.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*IP destino*],       [*Protocolo*],    [*Respuesta*],           [*Estado*],
    [`192.168.56.102`],   [TCP ACK],        [RST],                   [Activo ✓],
    [`192.168.56.102`],   [UDP],            [ICMP tipo 3 (filtrado)],[Activo ✓],
    [`192.168.56.102`],   [ICMP Timestamp], [ICMP tipo 14],          [Activo ✓],
    [`192.168.56.200`],   [TCP ACK],        [Sin respuesta],         [Inactivo ✗],
    [`192.168.56.200`],   [UDP],            [Sin respuesta],         [Inactivo ✗],
    [`192.168.56.200`],   [ICMP Timestamp], [Sin respuesta],         [Inactivo ✗],
  ),
  caption: [Resultados del descubrimiento de hosts — Escenario 2 (red host-only)],
)

El filtrado de respuestas ICMP tipo 3 (Port Unreachable) es clave para la correcta
interpretación de los resultados del vector UDP: la respuesta ICMP tipo 3 confirma
que el host está activo (el kernel respondió al paquete UDP), pero se excluye del
conjunto `vivos` para evitar doble conteo con las respuestas TCP y ICMP del mismo host.
Solo se reportan hosts que generan respuestas activas no-ICMP-3 @scapy_docs.

== Comportamiento por defecto de Nmap y estado de puertos

=== Concepto de estado de puerto

Un puerto es un punto de acceso lógico a un servicio en una máquina. Cada puerto está
identificado por un número (0-65535) y puede estar en uno de tres estados principales,
determinados por el tipo de respuesta que genera ante un estímulo enviado por el
escáner @nmap_guide.

Para comprender los estados de puerto, es fundamental entender el mecanismo de
establecimiento de conexión TCP: el three-way handshake. Una conexión TCP legítima
se establece en tres pasos:

1. El cliente envía un segmento TCP con el flag *SYN* activado.
2. Si el servidor tiene un servicio escuchando en ese puerto, responde con *SYN-ACK*.
3. El cliente completa el handshake enviando *ACK*.

Nmap aprovecha este mecanismo para determinar el estado del puerto sin completar la
conexión: envía el SYN inicial y observa la respuesta, pero nunca envía el ACK final.

#figure(
  table(
    columns: (auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Estado*],  [*Estímulo enviado*], [*Respuesta recibida*],
    [Abierto],   [TCP SYN], [TCP SYN-ACK: hay un servicio escuchando en ese puerto],
    [Cerrado],   [TCP SYN], [TCP RST-ACK: el host está activo pero no hay servicio],
    [Filtrado],  [TCP SYN], [Sin respuesta o ICMP tipo 3/13: firewall bloqueando],
  ),
  caption: [Estados de puerto TCP y sus estímulos y respuestas asociados],
)

El campo clave del paquete TCP que determina el estado es el conjunto de flags
(campo de 6 bits en la cabecera TCP): SYN-ACK (bits SYN y ACK activados) indica
puerto abierto, RST (bit RST activado) indica puerto cerrado, y la ausencia de
respuesta o un ICMP tipo 3 indica puerto filtrado @nmap_guide @wireshark.

=== Comportamiento por defecto de Nmap

Nmap es la herramienta de referencia en la industria para el descubrimiento de redes
y auditoría de seguridad @nmap_guide. Cuando se ejecuta con privilegios de root sin
especificar ningún tipo de escaneo (simplemente `nmap <objetivo>`), Nmap realiza por
defecto un *SYN Scan* (`-sS`), también conocido como escaneo "half-open" o
"stealth scan", combinado con una fase previa de descubrimiento de host.

==== Fase de descubrimiento de host (excluida del análisis de puertos)

Antes de escanear los puertos, Nmap verifica si el host está activo enviando una
combinación de paquetes: ICMP Echo Request, TCP SYN al puerto 443, TCP ACK al puerto
80 e ICMP Timestamp. Esta fase se descarta del análisis de puertos tal como indica
el enunciado, pero es importante conocerla para interpretar correctamente las capturas
de tráfico: los primeros paquetes que aparecen en Wireshark antes del escaneo SYN
pertenecen a esta fase.

==== Fase de escaneo de puertos: SYN Scan

El funcionamiento del SYN Scan es el siguiente @nmap_guide:

1. Nmap envía un paquete TCP con el flag SYN activo al puerto objetivo.
2. Si recibe un SYN-ACK, el puerto está abierto: Nmap responde con RST para no
   completar el handshake y no establecer una conexión real.
3. Si recibe un RST, el puerto está cerrado.
4. Si no recibe respuesta (timeout) o recibe un ICMP unreachable, el puerto está filtrado.

Este comportamiento hace al SYN Scan más sigiloso que un TCP Connect Scan (`-sT`),
que sí completa el three-way handshake y establece conexiones TCP reales, lo que deja
registro en los logs de los servicios objetivo. El SYN Scan, al no completar la
conexión, evita este registro en la mayoría de los servicios, aunque los sistemas IDS
modernos lo detectan igualmente por el patrón de tráfico.

Los parámetros por defecto de Nmap son @nmap_guide:

#figure(
  table(
    columns: (auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Parámetro*],           [*Valor por defecto*],
    [Tipo de escaneo],       [SYN Scan (`-sS`) con privilegios root],
    [Puertos escaneados],    [1000 puertos TCP más comunes],
    [Paquetes por puerto],   [1 SYN],
    [Total paquetes aprox.], [\~1000 SYN + paquetes de descubrimiento de host],
    [Timeout],               [Adaptativo según RTT de la red],
    [Resolución DNS],        [Activada por defecto],
    [Detección de versión],  [Desactivada (requiere `-sV`)],
    [Detección de SO],       [Desactivada (requiere `-O`)],
  ),
  caption: [Parámetros por defecto de Nmap en escaneo de puertos],
)

==== Comparativa con otros tipos de escaneo

Para contextualizar el SYN Scan dentro del ecosistema de técnicas de Nmap, se incluye
una comparativa con los tipos de escaneo más relevantes:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Tipo*],       [*Flag Nmap*], [*Requiere root*], [*Característica principal*],
    [SYN Scan],     [`-sS`],  [Sí],  [Half-open; no completa handshake; menos rastro],
    [Connect Scan], [`-sT`],  [No],  [Completa el handshake; registrado en logs],
    [UDP Scan],     [`-sU`],  [Sí],  [Escanea puertos UDP; lento por timeouts],
    [ACK Scan],     [`-sA`],  [Sí],  [Mapea reglas de firewall; no detecta servicios],
    [FIN Scan],     [`-sF`],  [Sí],  [Evasión avanzada; no funciona en Windows],
  ),
  caption: [Comparativa de tipos de escaneo de Nmap],
)

El SYN Scan es el equilibrio óptimo entre sigilo, velocidad y compatibilidad, lo que
explica su elección como comportamiento por defecto en Nmap @nmap_guide.

// ── 3. RESULTADOS Y EVIDENCIAS ────────────────────────────
= Resultados y Evidencias

== Evidencias Parte 1: Descubrimiento de hosts con Scapy

=== Ejecución del script

La siguiente captura muestra la ejecución del script `host_discovery.py` sobre la
interfaz loopback. Se observa cómo el script detecta correctamente `127.0.0.1` como
host activo y no reporta `192.168.99.99`, que no tiene ningún host asignado @scapy_docs.

#figure(
  image("images/terminal-parte1.png", width: 100%),
  caption: [Salida del script `host_discovery.py`: detección de host activo e inactivo],
)

=== Captura de tráfico — Tres protocolos simultáneos

La captura de Wireshark @wireshark tomada durante la ejecución del script sobre la
interfaz `eth0` muestra los tres tipos de paquetes enviados simultáneamente mediante
`sr()`: TCP ACK al puerto 80, UDP al puerto 80 e ICMP Timestamp (tipo 13). Se puede
observar en el panel de Wireshark que los paquetes llevan los campos correctos:
el TCP ACK tiene únicamente el flag ACK activado (sin SYN), el UDP va dirigido al
puerto 80, y el ICMP tipo 13 incluye los campos de timestamp. Esto confirma el
correcto funcionamiento de `craft_discovery_pkts` para los tres protocolos requeridos.

#figure(
  image("images/practica2wireshark.png", width: 100%),
  caption: [Captura Wireshark: paquetes TCP ACK, UDP e ICMP generados por `craft_discovery_pkts`],
)

=== Análisis del tráfico capturado

La captura muestra el comportamiento esperado para cada protocolo:

- *TCP ACK (fila 2)*: Paquete TCP de 54 bytes enviado desde el puerto efímero 43561
  al puerto 80 de `127.0.0.1`, con únicamente el flag ACK activo. El campo Sequence
  Number y Acknowledgment Number están a 0, lo que evidencia que no existe ninguna
  conexión establecida previa.
- *TCP RST (fila 4)*: Respuesta inmediata del sistema operativo con RST-ACK,
  confirmando que el host está activo pero que no existe la conexión referenciada por
  el ACK.
- *UDP (fila 5)*: Datagrama UDP de 42 bytes enviado al puerto 80 de `127.0.0.1`.
  La respuesta es un ICMP tipo 3 (Port Unreachable, fila 6), lo que confirma que el
  host está activo (el kernel respondió) aunque el puerto UDP 80 esté cerrado.
- *ICMP (filas 7-8)*: ICMP Echo Request (tipo 8) y su correspondiente Echo Reply
  (tipo 0), confirmando la conectividad con el host.

== Evidencias Parte 2: Escaneo de puertos con Nmap

=== Salida del escaneo Nmap

Antes de analizar el tráfico a nivel de paquete, se muestra la salida directa del
comando `sudo nmap 127.0.0.1` ejecutado sobre la máquina Kali Linux con los servicios
Apache2 y SSH activos. La salida confirma los dos puertos abiertos detectados (22/tcp
y 80/tcp), el número de puertos cerrados (998) y la latencia prácticamente nula
característica del escaneo sobre loopback.

#figure(
  image("images/nmap-salida.png", width: 90%),
  caption: [Salida de terminal: `sudo nmap 127.0.0.1` con puertos 22 (SSH) y 80 (HTTP) abiertos],
)

La línea `Not shown: 998 closed tcp ports (reset)` evidencia que Nmap recibió
respuestas RST-ACK en 998 puertos de los 1000 escaneados por defecto, lo que
confirma empíricamente el conteo de paquetes descrito en la tabla de parámetros
por defecto de Nmap.

=== Puertos abiertos: SSH (22) y HTTP (80)

Para obtener evidencias del comportamiento de Nmap a nivel de paquete, se activaron
los servicios Apache2 (HTTP, puerto 80) y SSH (puerto 22) en la máquina Kali Linux
y se ejecutó el escaneo sobre `127.0.0.1` mediante la interfaz loopback @wireshark.

El filtro `tcp.port == 22 || tcp.port == 80` en Wireshark @wireshark muestra el
intercambio de paquetes característico del SYN Scan sobre los puertos abiertos:
Nmap envía un SYN, el servicio responde con SYN-ACK confirmando que está escuchando,
y Nmap cierra inmediatamente con un RST sin completar el handshake.

#figure(
  image("images/tcp_port-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: secuencia SYN → SYN-ACK → RST en puertos 22 (SSH) y 80 (HTTP) abiertos],
)

La captura confirma el comportamiento teórico del SYN Scan: se puede observar que
Nmap envía el paquete SYN, recibe el SYN-ACK del servicio SSH (puerto 22) y del
servicio HTTP Apache2 (puerto 80), y responde inmediatamente con RST en ambos casos,
sin enviar el ACK que completaría el handshake. Esta secuencia incompleta es la
característica definitoria del escaneo "half-open".

=== Paquetes SYN enviados por Nmap

El filtro `tcp.flags.syn == 1 && tcp.flags.ack == 0` aísla únicamente los paquetes
SYN enviados por Nmap @wireshark, confirmando que se envía exactamente un paquete SYN
por puerto escaneado. Se observan paquetes dirigidos a múltiples puertos de forma
prácticamente simultánea (diferencias de microsegundos entre paquetes consecutivos),
lo que ilustra la eficiencia del escaneo paralelo de Nmap.

#figure(
  image("images/syn&ack-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: paquetes SYN enviados por Nmap, uno por puerto escaneado],
)

En la captura se pueden distinguir los puertos destino de los paquetes SYN: 111
(rpcbind), 22 (SSH), 995 (POP3S), 80 (HTTP), 554 (RTSP), entre otros de los 1000
puertos más comunes que Nmap escanea por defecto. El hecho de que todos los paquetes
provengan del mismo puerto origen de Nmap y vayan dirigidos al host `127.0.0.1`
permite identificarlos inequívocamente como tráfico de escaneo.

=== Puertos cerrados: RST como respuesta

El filtro `tcp.flags.reset == 1` muestra las respuestas RST-ACK que el sistema
operativo envía ante los SYN recibidos en puertos sin servicio activo @wireshark.
La inmediatez de estas respuestas (prácticamente en el mismo instante que el SYN,
con diferencias de microsegundos) confirma que el host está activo pero no tiene
ningún servicio escuchando en esos puertos. Un puerto filtrado, en contraste,
no generaría ninguna respuesta, y Nmap lo marcaría como filtrado tras agotar el
timeout.

#figure(
  image("images/reset-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: respuestas RST-ACK del sistema operativo en puertos cerrados],
)

=== Puerto filtrado: simulación con iptables

Para completar el análisis de los tres estados de puerto, se simuló un puerto filtrado
mediante una regla `iptables` que descarta silenciosamente los paquetes SYN dirigidos
al puerto 8080:

```bash
sudo iptables -A INPUT -p tcp --dport 8080 -j DROP
sudo nmap -sS -p 8080 127.0.0.1
```

Con esta regla activa, Nmap reporta el puerto 8080 como `filtered` porque no recibe
ninguna respuesta (ni SYN-ACK ni RST) dentro del timeout configurado. En Wireshark,
aplicando el filtro `tcp.dstport == 8080`, se observa únicamente el paquete SYN
enviado por Nmap —en realidad dos intentos, ya que Nmap reintenta ante la ausencia
de respuesta— sin ninguna contestación del sistema, lo que confirma que la regla
DROP está funcionando correctamente.

#figure(
  image("images/filtered-practica2-wireshark.png", width: 100%),
  caption: [Wireshark: filtro `tcp.dstport == 8080` — solo SYN sin respuesta, puerto filtrado por `iptables`],
)

Los dos paquetes SYN visibles (números 1 y 2, separados por ~1 segundo) corresponden
al intento inicial de Nmap y a su reintento ante la ausencia de respuesta: este
comportamiento de doble intento es característico del SYN Scan cuando no recibe
contestación, y es precisamente lo que distingue un puerto filtrado (timeout doble)
de uno cerrado (RST inmediato).

Una vez verificado el comportamiento, se elimina la regla `iptables` para no afectar
al resto de las pruebas:

```bash
sudo iptables -D INPUT -p tcp --dport 8080 -j DROP
```

=== Comparativa de resultados

#figure(
  table(
    columns: (auto, auto, auto, auto),
    fill: (_, row) => if row == 0 { rgb("#dddddd") } else { white },
    [*Puerto*], [*Servicio*], [*Estado Nmap*], [*Evidencia Wireshark*],
    [22/tcp],   [SSH],      [Abierto],   [SYN → SYN-ACK → RST],
    [80/tcp],   [HTTP],     [Abierto],   [SYN → SYN-ACK → RST],
    [111/tcp],  [rpcbind],  [Cerrado],   [SYN → RST-ACK],
    [139/tcp],  [netbios],  [Cerrado],   [SYN → RST-ACK],
    [443/tcp],  [https],    [Cerrado],   [SYN → RST-ACK],
    [8080/tcp], [(ninguno)],[Filtrado],  [SYN → (sin respuesta)],
  ),
  caption: [Comparativa de estados de puerto observados con Nmap y verificados con Wireshark],
)

// ── 4. ESTRUCTURA DEL REPOSITORIO ─────────────────────────
= Estructura del repositorio

El código fuente, las evidencias y la documentación de esta práctica se encuentran
organizados en un repositorio Git con la siguiente estructura:

```
Laboratorio-hacking-uem/
├── P2_Reconocimiento_activo/
│   ├── src/
│   │   └── host_discovery.py        # Implementación principal
│   ├── images/                       # Capturas de pantalla y Wireshark
│   │   ├── terminal-parte1.png
│   │   ├── practica2wireshark.png
│   │   ├── tcp_port-practica2-wireshark.png
│   │   ├── syn&ack-practica2-wireshark.png
│   │   └── reset-practica2-wireshark.png
│   ├── report/
│   │   ├── main.typ                  # Fuente del informe (Typst)
│   │   └── bibliography.bib          # Referencias bibliográficas
│   └── README.md                     # Descripción del entorno y ejecución
└── README.md                         # Descripción general del repositorio
```

El fichero `README.md` de la práctica incluye las instrucciones necesarias para
reproducir los resultados: versiones de software utilizadas, comandos de instalación
de dependencias (`pip install scapy`) y los comandos exactos de ejecución del script
con y sin privilegios de root.

La separación entre código fuente (`src/`), evidencias (`images/`) y documentación
(`report/`) facilita la navegación del repositorio y sigue las convenciones habituales
en proyectos de seguridad documentados.

// ── 5. CONCLUSIONES ───────────────────────────────────────
= Conclusiones

Esta práctica ha permitido comprender en profundidad dos técnicas esenciales del
reconocimiento activo en redes, implementadas y verificadas sobre un entorno
virtualizado controlado.

En cuanto al descubrimiento de hosts, la implementación con Scapy @scapy_docs demuestra
que el uso combinado de múltiples protocolos (TCP ACK, UDP, ICMP) aumenta
significativamente la fiabilidad de la detección frente a hosts que puedan filtrar
alguno de ellos individualmente. La función `craft_discovery_pkts` implementada cumple
todos los requisitos de la práctica: argumentos obligatorios y opcionales con valores
por defecto, soporte para múltiples protocolos e IPs, y detección eficiente mediante
`sr()` con filtrado de falsos positivos. La elección del centinela `None` para el
argumento `packet_counts` refleja buenas prácticas de Python, y el diseño modular
facilita la extensión de la función con nuevos protocolos (por ejemplo, ARP discovery
para redes locales) sin modificar la interfaz existente.

Un aspecto a destacar es la limitación encontrada con el ICMP Timestamp (tipo 13)
sobre la interfaz loopback de Linux: el kernel no procesa este tipo de solicitudes
en `lo`, lo que obligó a validar este vector sobre la interfaz `eth0` hacia la
máquina Metasploitable2. Esta limitación ilustra la importancia de conocer el entorno
de pruebas en detalle y de no asumir que todos los sistemas responden de forma
homogénea a los mismos estímulos.

Respecto al análisis de Nmap @nmap_guide, se ha verificado mediante capturas de
Wireshark @wireshark que su comportamiento por defecto consiste en un SYN Scan sobre
los 1000 puertos TCP más comunes, enviando exactamente un paquete SYN por puerto.
La distinción entre los tres estados de puerto (abierto, cerrado y filtrado) queda
claramente reflejada en las capturas: SYN-ACK para puertos abiertos, RST-ACK para
puertos cerrados, y ausencia de respuesta para puertos filtrados simulados con
`iptables`. La comparativa entre tipos de escaneo permite además contextualizar el
SYN Scan dentro del espectro de técnicas disponibles en Nmap, comprendiendo por qué
es el comportamiento por defecto.

Desde una perspectiva defensiva, esta práctica pone de manifiesto que la mera
presencia de un firewall no garantiza la invisibilidad de un host: un firewall que
bloquea SYN pero permite ACK puede seguir siendo identificado mediante TCP ACK
discovery, y un firewall que bloquea ICMP Echo puede ignorar el ICMP Timestamp.
Una estrategia defensiva robusta debe contemplar la configuración exhaustiva del
firewall para todos los vectores de descubrimiento relevantes, combinada con sistemas
IDS que detecten los patrones de escaneo incluso cuando los paquetes individuales
parecen legítimos.

Finalmente, ambas técnicas deben emplearse exclusivamente sobre entornos propios o
con autorización expresa, dado que su uso no autorizado sobre sistemas de terceros
constituye una infracción legal grave bajo la legislación española y europea vigente.

// ── BIBLIOGRAFÍA ──────────────────────────────────────────
= Bibliografía

#bibliography("bibliography.bib", style: "ieee")
