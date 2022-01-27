// Templated by Terraform
export const crudApiTables = ${ crud_api_tables };
export const crudApiUrl = "${crud_api_url}";
export const crudApiKey = "${crud_api_key}";
export const textractApiUrl = "${textract_api_url}";
export const imageUploadBucketUrl = "${image_upload_bucket_url}";

export async function getTableEntries(table = crudApiTables[0]) {
  const response = await fetch(crudApiUrl + table, {
    headers: { "x-api-key": crudApiKey }
  });
  if (!response.ok) {
    throw new Error("HTTP error! status: " + response.status);
  };
  return response.json();
};

export async function createOrDeleteTableEntries(table = crudApiTables[0], operation = "put", entries = []) {
  const response = await fetch(crudApiUrl + table, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": crudApiKey
    },
    body: JSON.stringify({ "operation": operation, "items": entries })
  });
  if (!response.ok) {
    throw new Error("HTTP error! status: " + response.status);
  };
  return response.json();
};
