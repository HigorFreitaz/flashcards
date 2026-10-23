import swaggerJSDoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Lume Flashcards API',
      version: '1.0.0',
      description: 'Documentação da API REST do Lume Flashcards com PostgreSQL',
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Servidor Local',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'Opaque session token',
        },
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            email: { type: 'string' },
          },
        },
        Flashcard: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            front: { type: 'string' },
            back: { type: 'string' },
            type: { type: 'string', enum: ['text', 'audio', 'image'] },
            status: { type: 'string', enum: ['novo', 'aRevisar', 'dominado'] },
            hint: { type: 'string', nullable: true },
            options: { type: 'array', items: { type: 'string' }, nullable: true },
            correctIndex: { type: 'integer', nullable: true },
            audioSeconds: { type: 'integer' },
            aiGenerated: { type: 'boolean' },
            mediaCaption: { type: 'string', nullable: true },
          },
        },
        Deck: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            description: { type: 'string' },
            dailyGoal: { type: 'integer' },
            remindersEnabled: { type: 'boolean' },
            reminderTimes: { type: 'array', items: { type: 'string' } },
            updatedAt: { type: 'string', format: 'date-time' },
            cards: { type: 'array', items: { $ref: '#/components/schemas/Flashcard' } },
          },
        },
      },
    },
  },
  apis: ['./src/routes/*.js'],
};

export const swaggerSpec = swaggerJSDoc(options);

const str = { type: 'string' }, integer = { type: 'integer' }, boolean = { type: 'boolean' };
const challengeBody = { title: str, targetCount: integer, deckIds: {type:'array',items:str}, durationDays: integer, weakOnly: boolean, status: {type:'string',enum:['cancelled']} };
const notificationBody = { title:str,body:str,scheduledAt:{type:'string',format:'date-time'},unread:boolean,retryPush:boolean };
const routes = [
 ['/auth/signup','post','Criar conta',{name:str,email:str,password:str},true],
 ['/auth/login','post','Entrar',{email:str,password:str},true],
 ['/auth/me','get','Restaurar sessão'], ['/auth/profile','put','Editar perfil',{name:str,email:str,password:str}],
 ['/auth/logout','post','Encerrar sessão',{}], ['/auth/account','delete','Excluir conta'],
 ['/auth/forgot-password','post','Solicitar código de recuperação',{email:str},true],
 ['/auth/reset-password','post','Redefinir senha',{token:str,password:str},true],
 ['/progress','get','Consultar progresso'], ['/progress','delete','Zerar progresso e cancelar desafios ativos'], ['/progress/history','get','Histórico (50 registros por página)'],
 ['/challenges','get','Listar desafios'], ['/challenges','post','Criar desafio personalizado',challengeBody],
 ['/challenges/join','post','Participar do desafio semanal',{}], ['/challenges/{id}','put','Editar/cancelar desafio',challengeBody], ['/challenges/{id}','delete','Excluir desafio'],
 ['/notifications','get','Listar avisos e lembretes agendados'], ['/notifications','post','Agendar aviso',notificationBody],
 ['/notifications/read-all','put','Marcar avisos entregues como lidos',{}], ['/notifications/{id}','put','Editar aviso ou repetir push',notificationBody], ['/notifications/{id}','delete','Excluir aviso'],
 ['/notifications/devices','post','Registrar dispositivo push',{token:str,platform:{type:'string',enum:['android','ios','unknown']}}],
 ['/settings','get','Ler preferências'], ['/settings','put','Salvar preferências',{themeMode:{type:'string',enum:['light','dark','system']},biometricLockEnabled:boolean,timeZone:str}], ['/settings','delete','Restaurar padrões'],
 ['/decks/{id}/cards/batch','post','Salvar cartões gerados em transação',{cards:{type:'array',items:{$ref:'#/components/schemas/Flashcard'}}}],
];
swaggerSpec.security = [{bearerAuth:[]}];
for (const [path, method, summary, properties, publicRoute] of routes) {
  swaggerSpec.paths[path] ??= {};
  swaggerSpec.paths[path][method] = { summary, tags:[path.split('/')[1]], security:publicRoute?[]:[{bearerAuth:[]}],
    parameters:[...path.matchAll(/\{(\w+)\}/g)].map(match=>({name:match[1],in:'path',required:true,schema:str})),
    ...(properties ? {requestBody:{required:true,content:{'application/json':{schema:{type:'object',properties}}}}}:{}),
    responses:{200:{description:'Sucesso'},201:{description:'Criado'},204:{description:'Concluído'},400:{description:'Dados inválidos'},401:{description:'Sessão inválida'},404:{description:'Não encontrado'},409:{description:'Conflito'},503:{description:'Entrega não configurada ou indisponível'}},
  };
}
swaggerSpec.paths['/progress/history'].get.parameters.push({name:'offset',in:'query',schema:{type:'integer',minimum:0}});
