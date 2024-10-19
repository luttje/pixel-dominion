const handler = require('serve-handler');
const http = require('http');

const webSourceDirectory = process.argv[2] || './builds/web';
const port = process.argv[3] ? parseInt(process.argv[3], 10) : 8000;

const server = http.createServer((request, response) => {
  return handler(request, response, {
    public: webSourceDirectory,
    headers: [
      {
        source: '**/*',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
        ],
      },
    ],
  });
});

server.listen(port, () => {
  console.log(`Running at http://localhost:${port}`);
});
