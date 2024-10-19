/**
 * This script packages the game files into a .love file.
 */
const fs = require('fs');
const archiver = require('archiver');

// Get the source directory that contains the game files
const sourceDir = process.argv[2];

// Get the output directory where the .love file will be saved
const outputFile = process.argv[3];

const output = fs.createWriteStream(outputFile);

const archive = archiver('zip', {
  zlib: { level: 9 } // Sets the compression level.
});

archive.on('error', function(err) {
  throw err;
})

archive.pipe(output);

archive.directory(sourceDir, false);

archive.finalize();

console.log('Packaging .love complete!');
