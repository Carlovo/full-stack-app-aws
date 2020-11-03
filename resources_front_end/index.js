"use strict";

var mainTable = document.getElementById("mainTable");
var sortOptions = [
    "Priority",
    "Timestamp",
    "Checkboxes",
    "Name"
];

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

    this.appendItemRow = function (tableEntry, entryNumber) {

        var tr = mainTable.insertRow(-1);
        tr.setAttribute("id", "tr-" + entryNumber);

        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntry["id"];
        idCell.setAttribute("id", "Id-" + entryNumber);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.style.fontSize = "x-small";
            timestampCell.style.fontStyle = "italic";
            timestampCell.innerHTML = tableEntry["timestamp"];
            timestampCell.setAttribute("id", "Timestamp-" + entryNumber);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);

            var cbCheck = document.createElement("input");
            checkCell.setAttribute("class", "check");
            cbCheck.setAttribute("type", "checkbox");
            cbCheck.checked = tableEntry["check"];
            cbCheck.setAttribute("id", "Check-" + entryNumber);
            cbCheck.setAttribute("onclick", "minimalApp.updateItemCheck(" + entryNumber + ")");
            checkCell.appendChild(cbCheck);
        };

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.innerHTML = tableEntry["priority"];
            priorityCell.setAttribute("id", "Priority-" + entryNumber);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.innerHTML = tableEntry["name"];
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

    this.appendCreateRow = function () {

        var tr = mainTable.insertRow(-1);

        // these are just placeholders
        var idCell = tr.insertCell(-1);
        idCell.innerHTML = tableEntries.length;
        idCell.setAttribute("id", "Id-" + tableEntries.length);
        idCell.setAttribute("style", "display:none;");

        var cbOptionsTimestamp = document.getElementById("Options-Timestamp");

        if (cbOptionsTimestamp.checked) {

            var timestampCell = tr.insertCell(-1);
            timestampCell.setAttribute("id", "Timestamp-" + tableEntries.length);
        };

        var cbOptionsCheck = document.getElementById("Options-Checkboxes");

        if (cbOptionsCheck.checked) {

            var checkCell = tr.insertCell(-1);
            checkCell.setAttribute("class", "check");
            checkCell.setAttribute("id", "Check-" + tableEntries.length);
        };

        // these are actual content
        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = tr.insertCell(-1);
            priorityCell.setAttribute("id", "Priority-" + tableEntries.length);

            var priorityNumberBox = document.createElement("input");
            priorityNumberBox.setAttribute("type", "number");
            priorityNumberBox.setAttribute("value", 0);
            priorityNumberBox.setAttribute("style", "width: 40px; touch-action: none");

            priorityCell.appendChild(priorityNumberBox);
        };

        var nameCell = tr.insertCell(-1);
        nameCell.setAttribute("id", "Name-" + tableEntries.length);

        var nameTextBox = document.createElement("input");
        nameTextBox.setAttribute("type", "text");
        nameTextBox.setAttribute("value", "");
        nameTextBox.setAttribute("style", "touch-action: none");

        nameCell.appendChild(nameTextBox);

        var createCell = tr.insertCell(-1);

        minimalApp.appendStandardButton(
            createCell, "Create", tableEntries.length, "minimalApp.createItem()"
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

        var sortDirections = [];

        sortOptions.forEach(function (sortOption) {

            var checkDesc = document.getElementById(sortOption + "-sort-desc");

            if (checkDesc.checked) {

                var sortDirection = -1;
            } else {

                var sortDirection = 1;
            };

            sortDirections.push(sortDirection);
        });

        var sortFunctions = [
            (a, b) => sortDirections[0] * (a.priority - b.priority),
            (a, b) => sortDirections[1] * (a.timestamp.localeCompare(b.timestamp)),
            (a, b) => sortDirections[2] * (a.check.toString().localeCompare(b.check.toString())),
            (a, b) => sortDirections[3] * (a.name.localeCompare(b.name))
        ];

        var sortApply = [];

        // array.forEach handles breaks and returns too awkwardly to use below

        for (var entryNumber = 0; entryNumber < sortOptions.length; entryNumber++) {

            for (var entryNumber2 = 0; entryNumber2 < sortOptions.length - 1; entryNumber2++) {

                var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

                if (radioButton.checked) {

                    break;
                };
            };

            sortApply.push(sortFunctions[entryNumber2]);
        };

        tableEntries.sort(function (a, b) {

            for (var entryNumber = 0; entryNumber < sortApply.length; entryNumber++) {

                var sorted = sortApply[entryNumber](a, b);

                if (sorted != 0) {

                    return sorted;
                };
            };

            return 0;
        });

        var cbOptionsCrud = document.getElementById("Options-CRUD");

        if (cbOptionsCrud.checked) {

            minimalApp.appendCreateRow();
        };

        tableEntries.forEach((tableEntry, entryNumber) => minimalApp.appendItemRow(tableEntry, entryNumber));

        minimalApp.toggleDisabledInput(false);

        minimalApp.scaleContent();
    };

    this.createCustomTimestamp = function () {

        var timestamp = new Date();
        var timestampString = timestamp.toISOString();
        var customTimestamp = timestampString.substring(0, 19);
        return customTimestamp.replace("T", " ");
    };

    this.validateAlphanumericInput = function (entryNumber, currentPriority) {

        var valid = true;

        var nameCell = document.getElementById("Name-" + entryNumber);

        if (nameCell.childNodes[0].value == "") {

            alert("name field may not be empty");
            valid = false;
        };

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);

            if (priorityCell.childNodes[0].value == "") {

                alert("priority field may not be empty");
                valid = false;
            };

            currentPriority = Number(priorityCell.childNodes[0].value);
        };

        return [valid, nameCell.childNodes[0].value, currentPriority];
    };

    this.createItem = function () {

        var itemDict = {};
        var valid;

        [
            valid,
            itemDict["name"],
            itemDict["priority"]
        ] = minimalApp.validateAlphanumericInput(tableEntries.length, 0);

        if (valid) {

            itemDict["check"] = false;
            itemDict["timestamp"] = minimalApp.createCustomTimestamp();

            var cbOptionsOnline = document.getElementById("Options-Online");

            if (cbOptionsOnline.checked) {

                itemDict["operation"] = "Create";

                minimalApp.xhttpBackEnd(itemDict);
            } else {

                // this is not foolproof, but it's not used downstream in the current setup
                itemDict["id"] = tableEntries.length;

                console.log(itemDict);

                tableEntries.push(itemDict);

                minimalApp.buildMainTable();
            };
        };
    };

    this.updateItemNameAndPriority = function (entryNumber) {

        var itemDict = tableEntries[entryNumber];

        var valid;

        [
            valid,
            itemDict["name"],
            itemDict["priority"]
        ] = minimalApp.validateAlphanumericInput(entryNumber, itemDict["priority"]);

        if (valid) {

            var cbOptionsOnline = document.getElementById("Options-Online");

            if (cbOptionsOnline.checked) {

                itemDict["operation"] = "Save";

                minimalApp.xhttpBackEnd(itemDict);
            } else {

                console.log(itemDict);

                tableEntries[entryNumber] = itemDict

                minimalApp.buildMainTable();
            };
        };
    };

    this.updateItemCheck = function (entryNumber) {

        var inputElement = document.getElementById("Check-" + entryNumber);
        var itemDict = tableEntries[entryNumber];

        itemDict["operation"] = "Save";
        itemDict["check"] = inputElement.checked;

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            minimalApp.xhttpBackEnd(itemDict);
        } else {

            tableEntries[entryNumber]["check"] = inputElement.checked;

            console.log(itemDict);
        };
    };

    this.deleteItem = function (entryNumber) {

        var itemDict = tableEntries[entryNumber];
        itemDict["operation"] = "Delete";

        var cbOptionsOnline = document.getElementById("Options-Online");

        if (cbOptionsOnline.checked) {

            minimalApp.xhttpBackEnd(itemDict);
        } else {

            tableEntries.splice(entryNumber, 1);

            console.log(itemDict);

            minimalApp.buildMainTable();
        };
    };

    this.xhttpBackEnd = function (itemDict) {

        var payloadText = JSON.stringify(itemDict);
        var xhttp = new XMLHttpRequest();

        console.log(payloadText);

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

        var cbOptionsPriority = document.getElementById("Options-Priority");

        if (cbOptionsPriority.checked) {

            var priorityCell = document.getElementById("Priority-" + entryNumber);
            priorityCell.innerHTML = tableEntries[entryNumber]["priority"];
        };

        var nameCell = document.getElementById("Name-" + entryNumber);
        nameCell.innerHTML = tableEntries[entryNumber]["name"];

        minimalApp.toggleEditItemButtons(entryNumber, false);
    };

    this.radioButton2D = function (radioButtonClicked) {

        var entryNumber = radioButtonClicked.id.split("-")[2];

        for (var entryNumber2 = 0; entryNumber2 < sortOptions.length; entryNumber2++) {

            var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

            if (radioButton.checked && radioButton != radioButtonClicked) {

                radioButton.checked = false;
                radioButtonClicked = radioButton;

                break;
            };
        };

        for (var entryNumber = 0; entryNumber < sortOptions.length; entryNumber++) {

            for (var entryNumber2 = 0; entryNumber2 < sortOptions.length; entryNumber2++) {

                var radioButton = document.getElementById(sortOptions[entryNumber2] + "-sort-" + entryNumber);

                if (radioButton.checked) {

                    break;
                };
            };

            if (entryNumber2 == sortOptions.length) {

                var radioButton = document.getElementById(radioButtonClicked.id.split("-")[0] + "-sort-" + entryNumber);

                radioButton.checked = true;

                break;
            };
        };
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
