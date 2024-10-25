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

// archive.directory(sourceDir, false);

// Instead of adding the entire directory to the bundle, we reduce its size by
// not including any sounds that aren't used in .lua files
const soundAssetsDir = `assets/sounds`;
const soundFiles = [];

const getSoundFiles = (dir) => {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = `${dir}/${file}`;
    if (fs.statSync(filePath).isDirectory()) {
      getSoundFiles(filePath);
    } else {
      soundFiles.push(filePath.replace(`${sourceDir}/${soundAssetsDir}/`, ''));
    }
  });
};
getSoundFiles(`${sourceDir}/${soundAssetsDir}`);

// For quick searching we just concat all Lua files into one string
let concatenatedLuaFiles = '';

const getLuaFiles = (dir) => {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = `${dir}/${file}`;
    if (fs.statSync(filePath).isDirectory()) {
      getLuaFiles(filePath);
    } else {
      concatenatedLuaFiles += fs.readFileSync(filePath, 'utf8');
    }
  });
};

getLuaFiles(sourceDir);

const ignoredSoundFiles = soundFiles.filter(soundFile => {
  return !concatenatedLuaFiles.includes(soundFile);
}).map(soundFile => `${soundAssetsDir}/${soundFile}`);

console.log('Ignoring the following unreferenced sound files:', ignoredSoundFiles);

archive.glob('**', {
  ignore: ignoredSoundFiles,
  cwd: sourceDir
});

archive.finalize();

console.log('Packaging .love complete!');
