var apiUrl = "${api_url}"

var minimalApp = new function () {

    this.buildOptionsTable = function () {

        var table = document.getElementById("optionsTable");
        table.innerHTML = "";
        table.style.margin = "24px 0px";

        tr = table.insertRow(-1);

        var checkOptionCell = tr.insertCell(-1);
        checkOptionCell.innerHTML = "Checkboxes";

        var checkCell = tr.insertCell(-1);

        var cbCheck = document.createElement("input");
        cbCheck.setAttribute("type", "checkbox");
        cbCheck.setAttribute("id", "Options-Check");
        cbCheck.disabled = true;
        cbCheck.checked = false;
        cbCheck.setAttribute("onclick", "minimalApp.toggleCheckBoxes(this)");
        checkCell.appendChild(cbCheck);
    }

    this.buildMainTable = function (jsonText) {

        var tableEntries = JSON.parse(jsonText)

        var table = document.getElementById("mainTable");
        table.innerHTML = "";

        cbOptionsCheck = document.getElementById("Options-Check");
        cbOptionsCheck.disabled = false;
        cbOptionsCheck.checked = false;

        for (var entryNumber = 0; entryNumber < tableEntries.length; entryNumber++) {

            tr = table.insertRow(-1);

            var idCell = tr.insertCell(-1);
            idCell.innerHTML = tableEntries[entryNumber]["id"];
            idCell.setAttribute("id", "Id-" + entryNumber);
            idCell.setAttribute("style", "display:none;");

            var checkCell = tr.insertCell(-1);

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.checked = tableEntries[entryNumber]["check"];
            cbCheck.setAttribute("id", "Check-" + entryNumber);
            checkCell.setAttribute("style", "display:none;");
            checkCell.appendChild(cbCheck);

            var nameCell = tr.insertCell(-1);
            nameCell.innerHTML = tableEntries[entryNumber]["name"];
            nameCell.setAttribute("id", "Name-" + entryNumber);

            var updateCell = tr.insertCell(-1);

            var btUpdate = document.createElement("input");
            btUpdate.setAttribute("type", "button");
            btUpdate.setAttribute("value", "Update");
            btUpdate.setAttribute("id", "Update-" + entryNumber);
            btUpdate.setAttribute("onclick", "minimalApp.editItem(this)");
            updateCell.appendChild(btUpdate);

            var btCancel = document.createElement("input");
            btCancel.setAttribute("type", "button");
            btCancel.setAttribute("value", "Cancel");
            btCancel.setAttribute("id", "Cancel-" + entryNumber);
            btCancel.setAttribute("style", "display:none;");
            btCancel.setAttribute("onclick", "minimalApp.loadBuildMainTable()");
            updateCell.appendChild(btCancel);

            var btSave = document.createElement("input");
            btSave.setAttribute("type", "button");
            btSave.setAttribute("value", "Save");
            btSave.setAttribute("id", "Save-" + entryNumber);
            btSave.setAttribute("style", "display:none;");
            btSave.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
            updateCell.appendChild(btSave);

            var deleteCell = tr.insertCell(-1);
            var btDelete = document.createElement("input");
            btDelete.setAttribute("type", "button");
            btDelete.setAttribute("value", "Delete");
            btDelete.setAttribute("id", "Delete-" + entryNumber);
            btDelete.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
            deleteCell.appendChild(btDelete);
        }

        tr = table.insertRow(-1);

        // these are just placeholders
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = "-";
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var checkCell = tr.insertCell(-1);
        checkCell.setAttribute("class", "check");
        checkCell.innerHTML = "";
        checkCell.setAttribute("id", "Check-" + entryNumber);
        checkCell.setAttribute("style", "display:none;");

        // these are actual content
        var newCell = tr.insertCell(-1);
        newCell.setAttribute("id", "Name-" + entryNumber);

        var tBox = document.createElement("input");
        tBox.setAttribute("type", "text");
        tBox.setAttribute("value", "");
        tBox.setAttribute("style", "touch-action: none")

        newCell.appendChild(tBox);

        var createCell = tr.insertCell(-1);
        var btNew = document.createElement("input");
        btNew.setAttribute("type", "button");
        btNew.setAttribute("value", "Create");
        btNew.setAttribute("id", "Create-" + entryNumber);
        btNew.setAttribute("onclick", "minimalApp.updateBackEnd(this)");
        createCell.appendChild(btNew);
    }

    this.updateBackEnd = function (oButton) {

        var activeRow = oButton.id.split("-")[1];
        var idCell = document.getElementById("Id-" + activeRow);
        var nameCell = document.getElementById("Name-" + activeRow);

        if (nameCell.childNodes[0].value != "") {

            var xhttp = new XMLHttpRequest();

            xhttp.onreadystatechange = function () {

                if (this.readyState == 4 && this.status == 200) {

                    minimalApp.buildMainTable(this.responseText)
                    minimalApp.scaleContent()
                }
            }

            xhttp.open("POST", apiUrl, true);

            payload = JSON.stringify({
                "operation": oButton.value,
                "id": idCell.innerHTML,
                "name": nameCell.childNodes[0].value
            })

            xhttp.send(payload);

            var inputElements = document.getElementsByTagName("input");

            Object.keys(inputElements).forEach(function (key) {
                inputElements[key].disabled = true;
            });
        }
        else {

            alert("input field may not be empty");
        }
    }

    this.editItem = function (oButton) {

        var activeRow = oButton.id.split("-")[1];
        var nameCell = document.getElementById("Name-" + activeRow);

        var inputBox = document.createElement("input");
        inputBox.setAttribute("type", "text");
        inputBox.setAttribute("value", nameCell.innerText);
        inputBox.setAttribute("style", "touch-action: none")
        nameCell.innerText = "";
        nameCell.appendChild(inputBox);

        var btCancel = document.getElementById("Cancel-" + activeRow);
        btCancel.setAttribute("style", "display:block");

        var btSave = document.getElementById("Save-" + activeRow);
        btSave.setAttribute("style", "display:block");

        var btDelete = document.getElementById("Delete-" + activeRow);
        btDelete.setAttribute("style", "display:none");

        oButton.setAttribute("style", "display:none;");
    }

    this.toggleCheckBoxes = function (checkbox) {

        checkCells = document.getElementsByClassName("check")

        Object.keys(checkCells).forEach(function (key) {
            if (checkbox.checked) {
                checkCells[key].setAttribute("style", "display:block;");
            }
            else {
                checkCells[key].setAttribute("style", "display:none;");
            }
        });

        minimalApp.scaleContent()
    }

    this.scaleContent = function () {

        var containerDiv = document.getElementById("container");
        var mainTable = document.getElementById("mainTable");

        containerDiv.style["transform"] = "initial";
        containerDiv.style["transformOrigin"] = "initial";

        // scale contents to smallest window dimension and center
        var scale = Math.min(
            window.innerHeight / mainTable.offsetWidth,
            window.innerWidth / mainTable.offsetWidth
        );

        containerDiv.style.width = mainTable.offsetWidth + "px";
        containerDiv.style.margin = "auto";
        containerDiv.style["transform"] = "scale(" + scale + ")";
        containerDiv.style["transformOrigin"] = "center top";
    }

    this.loadBuildMainTable = function () {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                minimalApp.buildMainTable(this.responseText);
                minimalApp.scaleContent();
            }
        }

        xhttp.open("GET", apiUrl, true);
        xhttp.send();
    }
}

minimalApp.buildOptionsTable();
minimalApp.loadBuildMainTable();
