"use strict";

var mainTable = document.getElementById("mainTable");

var tableEntries = [];
var apiUrl = "${api_url}";

var minimalApp = new function () {

    this.appendStandardButton = function (parent, value, entryNumber, onclick) {

        var standardButton = document.createElement("input");
        standardButton.setAttribute("type", "button");
        standardButton.setAttribute("value", value);
        standardButton.setAttribute("id", value + "-" + entryNumber);
        standardButton.setAttribute("onclick", onclick);
        parent.appendChild(standardButton);
    };

    this.appendItemRow = function (entryNumber) {

        var tr = mainTable.insertRow(-1);
        tr.setAttribute("id", "tr-" + entryNumber);

        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntries[entryNumber]["id"];
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.style.fontSize = "x-small";
            timestampCell.style.fontStyle = "italic";
            timestampCell.innerHTML = tableEntries[entryNumber]["timestamp"];
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.checked = tableEntries[entryNumber]["check"];
            cbCheck.setAttribute("id", "Check-" + entryNumber);
            cbCheck.setAttribute("onclick", "minimalApp.updateItemCheck(" + entryNumber + ")");
            checkCell.appendChild(cbCheck);
        };

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.innerHTML = tableEntries[entryNumber]["priority"];
            priorityCell.setAttribute("id", "Priority-" + entryNumber);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.innerHTML = tableEntries[entryNumber]["name"];
        nameCell.setAttribute("id", "Name-" + entryNumber);

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            var updateCell = tr.insertCell(-1);

            minimalApp.appendStandardButton(
                updateCell, "Update", entryNumber, "minimalApp.editItem(this)"
            );
            minimalApp.appendStandardButton(
                updateCell, "Cancel", entryNumber, "minimalApp.cancelEditName(this)"
            );
            minimalApp.appendStandardButton(
                updateCell, "Save", entryNumber, "minimalApp.updateItemNameAndPriority(" + entryNumber + ")"
            );

            var deleteCell = tr.insertCell(-1);

            minimalApp.appendStandardButton(
                deleteCell, "Delete", entryNumber, "minimalApp.deleteItem(" + entryNumber + ")"
            );

            minimalApp.toggleEditItemButtons(entryNumber, false);
        };
    };

    this.appendCreateRow = function (entryNumber) {

        var tr = mainTable.insertRow(-1);

        // these are just placeholders
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = entryNumber;
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);
            checkCell.setAttribute("class", "check");
            checkCell.setAttribute("id", "Check-" + entryNumber);
        };

        // these are actual content
        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.setAttribute("id", "Priority-" + entryNumber);

            var priorityNumberBox = document.createElement("input");
            priorityNumberBox.setAttribute("type", "number");
            priorityNumberBox.setAttribute("value", 0);
            priorityNumberBox.setAttribute("style", "width: 40px; touch-action: none");

            priorityCell.appendChild(priorityNumberBox);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.setAttribute("id", "Name-" + entryNumber);

        var nameTextBox = document.createElement("input");
        nameTextBox.setAttribute("type", "text");
        nameTextBox.setAttribute("value", "");
        nameTextBox.setAttribute("style", "touch-action: none");

        nameCell.appendChild(nameTextBox);

        var createCell = tr.insertCell(-1);

        minimalApp.appendStandardButton(
            createCell, "Create", entryNumber, "minimalApp.createItem(" + entryNumber + ")"
        );

        // another placeholder
        tr.insertCell(-1);
    };

    this.toggleDisabledInput = function (disabled) {

        var inputElements = document.getElementsByTagName("input");

        Object.keys(inputElements).forEach(function (key) {
            inputElements[key].disabled = disabled;
        });
    };

    this.buildMainTable = function () {

        mainTable.innerHTML = "";

        var radioTimestampAsc = document.getElementById("Timestamp-sort-asc");

        if (radioTimestampAsc.checked) {

            tableEntries.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
        } else {

            var radioTimestampDesc = document.getElementById("Timestamp-sort-desc");

            if (radioTimestampDesc.checked) {

                tableEntries.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
            } else {

                var radioCheckAsc = document.getElementById("Checkboxes-sort-asc");

                if (radioCheckAsc.checked) {

                    tableEntries.sort((a, b) => a.check.toString().localeCompare(b.check.toString()));
                } else {

                    var radioCheckDesc = document.getElementById("Checkboxes-sort-desc");

                    if (radioCheckDesc.checked) {

                        tableEntries.sort((a, b) => b.check.toString().localeCompare(a.check.toString()));
                    } else {

                        var radioPriorityAsc = document.getElementById("Priority-sort-asc");

                        if (radioPriorityAsc.checked) {

                            tableEntries.sort((a, b) => a.priority - b.priority);
                        } else {

                            tableEntries.sort((a, b) => b.priority - a.priority);
                        };
                    };
                };
            };
        };

        for (var entryNumber = 0; entryNumber < tableEntries.length; entryNumber++) {

            minimalApp.appendItemRow(entryNumber);
        };

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            minimalApp.appendCreateRow(entryNumber);
        };

        minimalApp.toggleDisabledInput(false);

        minimalApp.scaleContent();
    };

    this.createCustomTimestamp = function () {

        var timestamp = new Date();
        var timestampString = timestamp.toISOString();
        var customTimestamp = timestampString.substring(0, 19);
        return customTimestamp.replace("T", " ");
    };

    this.validateAlphanumericInput = function (entryNumber, itemDict) {

        var nameCell = document.getElementById("Name-" + entryNumber);

        if (nameCell.childNodes[0].value == "") {

            alert("name field may not be empty");
            return;
        };

        itemDict["name"] = nameCell.childNodes[0].value;

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);

            if (priorityCell.childNodes[0].value == "") {

                alert("priority field may not be empty");
                return;
            };

            itemDict["priority"] = Number(priorityCell.childNodes[0].value);
        } else {

            itemDict["priority"] = tableEntries[entryNumber]["priority"];
        };

        itemDict["id"] = tableEntries[entryNumber]["id"];
        itemDict["check"] = tableEntries[entryNumber]["check"];
        itemDict["timestamp"] = tableEntries[entryNumber]["timestamp"];

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            minimalApp.xhttpBackEnd(itemDict);
        } else {

            tableEntries[entryNumber] = itemDict;

            minimalApp.buildMainTable();
        };
    };

    this.createItem = function (entryNumber) {

        var itemDict = {};
        itemDict["operation"] = "Create";

        tableEntries.push({
            "id": entryNumber,
            "check": false,
            "priority": 0,
            "timestamp": minimalApp.createCustomTimestamp()
        });

        minimalApp.validateAlphanumericInput(entryNumber, itemDict);
    };

    this.updateItemNameAndPriority = function (entryNumber) {

        var itemDict = {};
        itemDict["operation"] = "Save";

        minimalApp.validateAlphanumericInput(entryNumber, itemDict);
    };

    this.updateItemCheck = function (entryNumber) {

        var inputElement = document.getElementById("Check-" + entryNumber);

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            var itemDict = {};
            itemDict["id"] = tableEntries[entryNumber]["id"];
            itemDict["operation"] = "Save";
            itemDict["name"] = tableEntries[entryNumber]["name"];
            itemDict["priority"] = tableEntries[entryNumber]["priority"];
            itemDict["check"] = inputElement.checked;

            minimalApp.xhttpBackEnd(itemDict);
        } else {

            tableEntries[entryNumber]["check"] = inputElement.checked;
        };
    };

    this.deleteItem = function (entryNumber) {

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            var itemDict = {};
            itemDict["id"] = tableEntries[entryNumber]["id"];
            itemDict["operation"] = "Delete";

            minimalApp.xhttpBackEnd(itemDict);
        } else {

            tableEntries.splice(entryNumber, 1);

            minimalApp.buildMainTable();
        };
    };

    this.xhttpBackEnd = function (itemDict) {

        var payloadText = JSON.stringify(itemDict);
        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                tableEntries = JSON.parse(this.responseText);

                minimalApp.buildMainTable();
            };
        };

        xhttp.open("POST", apiUrl, true);

        xhttp.send(payloadText);

        minimalApp.toggleDisabledInput(true);
    };

    this.editItem = function (oButton) {

        var entryNumber = oButton.id.split("-")[1];

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);

            var priorityNumberBox = document.createElement("input");
            priorityNumberBox.setAttribute("type", "number");
            priorityNumberBox.setAttribute("value", tableEntries[entryNumber]["priority"]);
            priorityNumberBox.setAttribute("style", "width: 40px; touch-action: none");
            priorityCell.innerText = "";
            priorityCell.appendChild(priorityNumberBox);
        };

        var nameCell = document.getElementById("Name-" + entryNumber);

        var nameTextBox = document.createElement("input");
        nameTextBox.setAttribute("type", "text");
        nameTextBox.setAttribute("value", tableEntries[entryNumber]["name"]);
        nameTextBox.setAttribute("style", "touch-action: none");
        nameCell.innerText = "";
        nameCell.appendChild(nameTextBox);

        minimalApp.toggleEditItemButtons(entryNumber, true);
    };

    this.cancelEditName = function (oButton) {

        var entryNumber = oButton.id.split("-")[1];

        var priorityCell = document.getElementById("Priority-" + entryNumber);
        priorityCell.innerHTML = tableEntries[entryNumber]["priority"];

        var nameCell = document.getElementById("Name-" + entryNumber);
        nameCell.innerHTML = tableEntries[entryNumber]["name"];

        minimalApp.toggleEditItemButtons(entryNumber, false);
    };

    this.toggleEditItemButtons = function (entryNumber, editMode) {

        if (editMode) {

            var nameEditDisplay = "block";
            var optionsDisplay = "none";
        } else {

            var nameEditDisplay = "none";
            var optionsDisplay = "block";
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var cbCheck = document.getElementById("Check-" + entryNumber);
            cbCheck.setAttribute("style", "display:" + optionsDisplay);
        };

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            var btUpdate = document.getElementById("Update-" + entryNumber);
            btUpdate.setAttribute("style", "display:" + optionsDisplay);
            var btDelete = document.getElementById("Delete-" + entryNumber);
            btDelete.setAttribute("style", "display:" + optionsDisplay);

            var btCancel = document.getElementById("Cancel-" + entryNumber);
            btCancel.setAttribute("style", "display:" + nameEditDisplay);
            var btSave = document.getElementById("Save-" + entryNumber);
            btSave.setAttribute("style", "display:" + nameEditDisplay);
        };
    };

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
    };

    this.loadBuildMainTable = function () {

        var xhttp = new XMLHttpRequest();

        xhttp.onreadystatechange = function () {

            if (this.readyState == 4 && this.status == 200) {

                tableEntries = JSON.parse(this.responseText);

                minimalApp.buildMainTable();
            };
        };

        xhttp.open("GET", apiUrl, true);
        xhttp.send();
    };
};

minimalApp.loadBuildMainTable();
