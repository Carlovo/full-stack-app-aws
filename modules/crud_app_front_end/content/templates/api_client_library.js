// Templated by Terraform
export const crudApiTables = ${ crud_api_tables };
export const crudApiUrl = "${crud_api_url}";
export const crudApiKey = "${crud_api_key}";
export const textractApiUrl = "${textract_api_url}";
export const imageUploadBucketUrl = "${image_upload_bucket_url}";

export async function queryCrudApi(resource = crudApiTables[0], method = "GET", bodyObject = {}) {
  const requestDetails = {
    method: method,
    headers: { "x-api-key": crudApiKey }
  };
  if (Object.keys(bodyObject).length > 0) {
    requestDetails["headers"]["Content-Type"] = "application/json"
    requestDetails["body"] = JSON.stringify(bodyObject)
  };

  const response = await fetch(crudApiUrl + resource, requestDetails);
  if (!response.ok) {
    throw new Error("HTTP error! status: " + response.status);
  };
  return response.json();
};

export async function getTableEntries(table = crudApiTables[0]) {
  return queryCrudApi(table);
};

export async function createTableEntries(table = crudApiTables[0], entries = []) {
  return queryCrudApi(
    table,
    "POST",
    { "operation": "put", "items": entries }
  );
};

export async function deleteTableEntries(table = crudApiTables[0], entries = []) {
  return queryCrudApi(
    table,
    "POST",
    { "operation": "delete", "items": entries }
  );
};

export async function deleteTableEntry(table = crudApiTables[0], entryId = "") {
  return queryCrudApi(
    table + "/" + entryId,
    "DELETE"
  );
};

export async function updateTableEntry(table = crudApiTables[0], entryId = "", newValue = {}) {
  return queryCrudApi(
    table + "/" + entryId,
    "PATCH",
    newValue
  );
};
