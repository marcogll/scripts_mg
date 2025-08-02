
# install-ltunify.sh

Este script automatiza la instalación, compilación y configuración de **ltunify** en Ubuntu. Incluye:

- Instalación de dependencias (`git`, `build-essential`, `libhidapi-dev`)
- Clonado o actualización del repositorio
- Compilación del binario
- Instalación en `~/bin` y ajuste de `PATH`
- Creación y asignación del grupo `plugdev`
- Instalación de reglas udev para acceso a `/dev/hidraw*`
- Recarga de reglas udev

---

## Uso rápido

### 1. Ejecutar directamente con **curl**

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh | bash
````

### 2. Ejecutar directamente con **wget**

```bash
wget -qO- https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh | bash
```

---

## Pasos detallados

1. **Descarga y ejecución**

   * **curl**:

     ```bash
     curl -fsSL <URL_SCRIPT> | bash
     ```
   * **wget**:

     ```bash
     wget -qO- <URL_SCRIPT> | bash
     ```

   Reemplaza `<URL_SCRIPT>` por
   `https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh`.

2. **Revisión del script (opcional)**

   * Para inspeccionar antes de ejecutar:

     ```bash
     curl -fsSL <URL_SCRIPT> | less
     ```
   * Para comprobación sintáctica con `bash -n`:

     ```bash
     curl -fsSL <URL_SCRIPT> | bash -n
     ```

3. **Después de la instalación**

   * **Cerrar y volver a abrir** la terminal (o `newgrp plugdev`) para aplicar el grupo `plugdev`.
   * Probar comandos:

     ```bash
     ltunify list
     ltunify pair
     ltunify info 0
     ltunify unpair 0
     ```

---

## Notas de seguridad

* **Revisa siempre** el contenido de scripts antes de ejecutarlos en tu sistema.
* Ejecuta como usuario normal; el script solicitará `sudo` cuando sea necesario.
* Mantén actualizado el script clonando periódicamente el repositorio si ya lo descargaste localmente.

---

```
```
