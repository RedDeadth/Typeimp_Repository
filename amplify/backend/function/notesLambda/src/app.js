/* Amplify Params - DO NOT EDIT
	AUTH_TYPEIMP628BA24A_USERPOOLID
	ENV
	REGION
	STORAGE_CATEGORIESTABLE_ARN
	STORAGE_CATEGORIESTABLE_NAME
	STORAGE_CATEGORIESTABLE_STREAMARN
	STORAGE_NOTESTABLE_ARN
	STORAGE_NOTESTABLE_NAME
	STORAGE_NOTESTABLE_STREAMARN
Amplify Params - DO NOT EDIT *//*
Copyright 2017 - 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at
    http://aws.amazon.com/apache2.0/
or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/

const { v4: uuidv4 } = require('uuid');
const express = require('express')
const bodyParser = require('body-parser')
const awsServerlessExpressMiddleware = require('aws-serverless-express/middleware')

// AWS SDK v3 imports
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, GetCommand, PutCommand, UpdateCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

// Configuracion con dynamodb
const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-2'
});
const ddb = DynamoDBDocumentClient.from(client);

const categoriesTableName = process.env.STORAGE_CATEGORIESTABLE_NAME;
const tableName = process.env.STORAGE_NOTESTABLE_NAME;


console.log('Environment variables:', {
  TABLE_NAME: tableName,
  CATEGORIES_TABLE_NAME: categoriesTableName,
  AWS_REGION: process.env.AWS_REGION
});
// declare a new express app
const app = express()
app.use(bodyParser.json())
app.use(awsServerlessExpressMiddleware.eventContext())

// Enable CORS for all methods
app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "*")
  res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  next()
});

function getUserId(req) {
  // Verificar si hay autorización de Cognito User Pool (JWT)
  if (req.apiGateway && 
      req.apiGateway.event && 
      req.apiGateway.event.requestContext && 
      req.apiGateway.event.requestContext.authorizer && 
      req.apiGateway.event.requestContext.authorizer.claims) {
    return req.apiGateway.event.requestContext.authorizer.claims.sub;
  }
  
  // Verificar si hay autenticación de Cognito Identity Pool
  if (req.apiGateway && 
      req.apiGateway.event && 
      req.apiGateway.event.requestContext && 
      req.apiGateway.event.requestContext.identity && 
      req.apiGateway.event.requestContext.identity.cognitoIdentityId) {
    return req.apiGateway.event.requestContext.identity.cognitoIdentityId;
  }
  
  // Si no se encuentra ningún método de autenticación
  console.log('No se pudo obtener el ID de usuario. RequestContext:', 
    JSON.stringify(req.apiGateway?.event?.requestContext, null, 2));
  return null;
}


app.get('/notes', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const params = {
    TableName: tableName,
    KeyConditionExpression: 'userId = :u',
    ExpressionAttributeValues: {
      ':u': userId,
    },
  };

  try {
    const data = await ddb.send(new QueryCommand(params));
    res.json({ success: true, notes: data.Items });
  } catch (err) {
    res.status(500).json({ error: 'Could not retrieve notes: ' + err.message });
  }
});

/**********************
 * GET /notes/:id - Get a specific note by ID for the authenticated user *
 **********************/
app.get('/notes/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const noteId = req.params.id;
  const params = {
    TableName: tableName,
    Key: {
      'userId': userId,
      'noteId': noteId
    },
  };

  try {
    const data = await ddb.send(new GetCommand(params));
    if (!data.Item) {
      return res.status(404).json({ error: 'Note not found.' });
    }
    res.json({ success: true, note: data.Item });
  } catch (err) {
    res.status(500).json({ error: 'Could not retrieve note: ' + err.message });
  }
});

/****************************
* POST /notes - Create a new note *
****************************/
app.post('/notes', async function(req, res) {
  console.log('POST /notes - Starting request');
  console.log('Request body:', JSON.stringify(req.body, null, 2));
  
  try {
      const userId = getUserId(req);
      if (!userId) {
          console.log('Error: User ID not found');
          return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
      }
      
      console.log('User ID obtained:', userId);

      const { title, content, categoryId } = req.body;
      if (!title || !content) {
          console.log('Error: Missing title or content');
          return res.status(400).json({ error: 'Title and content are required.' });
      }

      const now = new Date().toISOString();
      const noteId = uuidv4();
      
      console.log('Generated noteId:', noteId);

      const item = {
          userId: userId,
          noteId: noteId,
          title: title,
          content: content,
          categoryId: categoryId || 'Uncategorized',
          createdAt: now,
          updatedAt: now,
      };

      console.log('Item to save:', JSON.stringify(item, null, 2));

      const params = {
          TableName: tableName,
          Item: item,
      };

      console.log('DynamoDB params:', JSON.stringify(params, null, 2));

      const result = await ddb.send(new PutCommand(params));
      console.log('DynamoDB result:', JSON.stringify(result, null, 2));

      res.status(201).json({ 
          success: true, 
          message: 'Note created successfully', 
          note: item 
      });
      
  } catch (err) {
      console.error('Error creating note:', err);
      res.status(500).json({ 
          error: 'Could not create note: ' + err.message,
          details: err.stack 
      });
  }
});

/****************************
* PUT /notes/:id - Update an existing note *
****************************/
app.put('/notes/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const noteId = req.params.id;
  const { title, content, categoryId } = req.body;

  if (!title && !content && !categoryId) {
    return res.status(400).json({ error: 'No fields to update provided.' });
  }

  const now = new Date().toISOString();
  let updateExpression = 'set updatedAt = :updatedAt';
  let expressionAttributeValues = { ':updatedAt': now };

  if (title) {
    updateExpression += ', title = :title';
    expressionAttributeValues[':title'] = title;
  }
  if (content) {
    updateExpression += ', content = :content';
    expressionAttributeValues[':content'] = content;
  }
  if (categoryId) {
    updateExpression += ', categoryId = :categoryId';
    expressionAttributeValues[':categoryId'] = categoryId;
  }

  const params = {
    TableName: tableName,
    Key: {
      'userId': userId,
      'noteId': noteId
    },
    UpdateExpression: updateExpression,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW',
    ConditionExpression: 'attribute_exists(noteId)'
  };

  try {
    const data = await ddb.send(new UpdateCommand(params));
    res.json({ success: true, message: 'Note updated successfully', note: data.Attributes });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return res.status(404).json({ error: 'Note not found or you do not have permission to update it.' });
    }
    res.status(500).json({ error: 'Could not update note: ' + err.message });
  }
});

/****************************
* DELETE /notes/:id - Delete a note *
****************************/
app.delete('/notes/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const noteId = req.params.id;
  const params = {
    TableName: tableName,
    Key: {
      'userId': userId,
      'noteId': noteId
    },
    ConditionExpression: 'attribute_exists(noteId)'
  };

  try {
    await ddb.send(new DeleteCommand(params));
    res.json({ success: true, message: 'Note deleted successfully.' });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return res.status(404).json({ error: 'Note not found or you do not have permission to delete it.' });
    }
    res.status(500).json({ error: 'Could not delete note: ' + err.message });
  }
});

/**********************
 * GET /categories - Get all categories for the authenticated user *
 **********************/
app.get('/categories', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const params = {
    TableName: categoriesTableName, // Usar categoriesTableName
    KeyConditionExpression: 'userId = :u',
    ExpressionAttributeValues: {
      ':u': userId,
    },
  };

  try {
    const data = await ddb.send(new QueryCommand(params));
    res.json({ success: true, categories: data.Items });
  } catch (err) {
    res.status(500).json({ error: 'Could not retrieve categories: ' + err.message });
  }
});

/**********************
 * GET /categories/:id - Get a specific category by ID for the authenticated user *
 **********************/
app.get('/categories/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const categoryId = req.params.id;
  const params = {
    TableName: categoriesTableName, // Usar categoriesTableName
    Key: {
      'userId': userId,
      'categoryId': categoryId
    },
  };

  try {
    const data = await ddb.send(new GetCommand(params));
    if (!data.Item) {
      return res.status(404).json({ error: 'Category not found.' });
    }
    res.json({ success: true, category: data.Item });
  } catch (err) {
    res.status(500).json({ error: 'Could not retrieve category: ' + err.message });
  }
});

/****************************
* POST /categories - Create a new category *
****************************/
app.post('/categories', async function(req, res) {
  console.log('POST /categories - Starting request');
  try {
      const userId = getUserId(req);
      if (!userId) {
          return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
      }
      
      const { name } = req.body; // Solo necesitamos el nombre de la categoría
      if (!name) {
          return res.status(400).json({ error: 'Category name is required.' });
      }

      const now = new Date().toISOString();
      const categoryId = uuidv4(); // Generar un ID único para la categoría
      
      const item = {
          userId: userId,
          categoryId: categoryId,
          name: name,
          createdAt: now,
          updatedAt: now,
      };

      const params = {
          TableName: categoriesTableName, // Usar categoriesTableName
          Item: item,
          ConditionExpression: 'attribute_not_exists(categoryId)' // Evita crear categorías con el mismo ID si uuidv4 se repitiera (muy improbable)
      };

      await ddb.send(new PutCommand(params));

      res.status(201).json({ 
          success: true, 
          message: 'Category created successfully', 
          category: item 
      });
      
  } catch (err) {
      if (err.name === 'ConditionalCheckFailedException') {
        return res.status(409).json({ error: 'Category with this ID already exists (unlikely with uuidv4).' });
      }
      console.error('Error creating category:', err);
      res.status(500).json({ 
          error: 'Could not create category: ' + err.message,
          details: err.stack 
      });
  }
});

/****************************
* PUT /categories/:id - Update an existing category *
****************************/
app.put('/categories/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const categoryId = req.params.id;
  const { name } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Category name is required for update.' });
  }

  const now = new Date().toISOString();
  const params = {
    TableName: categoriesTableName, // Usar categoriesTableName
    Key: {
      'userId': userId,
      'categoryId': categoryId
    },
    UpdateExpression: 'set #name = :name, updatedAt = :updatedAt',
    ExpressionAttributeNames: { // Usamos ExpressionAttributeNames porque 'name' es una palabra reservada en DynamoDB
      '#name': 'name'
    },
    ExpressionAttributeValues: {
      ':name': name,
      ':updatedAt': now,
    },
    ReturnValues: 'ALL_NEW',
    ConditionExpression: 'attribute_exists(categoryId)' // Asegura que la categoría exista y sea del usuario
  };

  try {
    const data = await ddb.send(new UpdateCommand(params));
    res.json({ success: true, message: 'Category updated successfully', category: data.Attributes });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return res.status(404).json({ error: 'Category not found or you do not have permission to update it.' });
    }
    res.status(500).json({ error: 'Could not update category: ' + err.message });
  }
});

/****************************
* DELETE /categories/:id - Delete a category and its associated notes (cascading) *
****************************/
app.delete('/categories/:id', async function(req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
  }

  const categoryIdToDelete = req.params.id;

  try {
    // 1. Verificar si la categoría existe
    const getCategoryParams = {
      TableName: categoriesTableName,
      Key: {
        'userId': userId,
        'categoryId': categoryIdToDelete
      }
    };
    const categoryData = await ddb.send(new GetCommand(getCategoryParams));
    if (!categoryData.Item) {
      return res.status(404).json({ error: 'Category not found.' });
    }

    // 2. Buscar notas de este usuario y filtrar por categoría
    const queryNotesParams = {
      TableName: tableName, // notesTable
      IndexName: 'notesByCategory', // <--- ESTO ES CRUCIAL
      KeyConditionExpression: 'categoryId = :c', // <-- PK del GSI
      FilterExpression: 'userId = :u', // <-- Filtro sobre el GSI
      ExpressionAttributeValues: {
        ':u': userId,
        ':c': categoryIdToDelete,
      },
    };
    const associatedNotes = await ddb.send(new QueryCommand(queryNotesParams));

    // 3. Eliminar notas asociadas una por una (más simple)
    if (associatedNotes.Items && associatedNotes.Items.length > 0) {
      for (const note of associatedNotes.Items) {
        await ddb.send(new DeleteCommand({
          TableName: tableName,
          Key: {
            'userId': note.userId,
            'noteId': note.noteId
          }
        }));
      }
    }

    // 4. Eliminar la categoría
    await ddb.send(new DeleteCommand({
      TableName: categoriesTableName,
      Key: {
        'userId': userId,
        'categoryId': categoryIdToDelete
      }
    }));

    res.json({ success: true, message: 'Category and associated notes deleted successfully.' });

  } catch (err) {
    console.error('Error deleting category:', err);
    res.status(500).json({ error: 'Could not delete category: ' + err.message });
  }
});

module.exports = app