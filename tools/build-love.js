import { fileURLToPath } from 'url';
import archiver from 'archiver';
import process from 'process';
import chalk from 'chalk';
import fs from 'fs';

/**
 * Packages game files into a .love file while excluding unused sound assets.
 * @param {string} sourceDir - Source directory containing game files
 * @param {string} outputFile - Path for the output .love file
 * @returns {Promise<void>}
 */
async function packageLoveGame(sourceDir, outputFile) {
  if (!sourceDir || !outputFile) {
    throw new Error('Source directory and output file path are required');
  }

  // Create write stream and archive
  const output = fs.createWriteStream(outputFile);
  const archive = archiver('zip', {
    zlib: { level: 9 } // Maximum compression
  });

  // Set up archive event handlers
  archive.pipe(output);

  archive.on('error', (err) => {
    throw new Error(`Archive error: ${err.message}`);
  });

  // Get list of all sound files
  const soundAssetsDir = 'assets/sounds';
  const fullSoundAssetsDir = `${sourceDir}/${soundAssetsDir}`;
  const soundFiles = getAllFiles(fullSoundAssetsDir)
    .map(file => file.replace(`${fullSoundAssetsDir}/`, ''));

  // Get concatenated content of all Lua files
  const luaContent = getAllLuaContent(sourceDir);

  // Find unused sound files by checking if they are referenced in Lua files
  const unusedSoundFiles = soundFiles
    .filter(soundFile => !luaContent.includes(soundFile))
    .map(soundFile => `${soundAssetsDir}/${soundFile}`);

  console.log(
    chalk.gray('Excluding unused sound files (to reduce bundle size):\n - ', unusedSoundFiles.join('\n - '))
  );

  // Add files to archive, excluding unused sounds
  archive.glob('**', {
    ignore: unusedSoundFiles,
    cwd: sourceDir
  });

  // Return promise that resolves when archive is finalized
  return new Promise((resolve, reject) => {
    output.on('close', () => {
      console.log(
        chalk.green('\nSuccessfully created .love package!')
      );

      resolve();
    });

    output.on('error', reject);
    archive.finalize();
  });
}

/**
 * Recursively gets all files in a directory
 * @param {string} dir - Directory to scan
 * @returns {string[]} Array of file paths
 */
function getAllFiles(dir) {
  const files = [];

  function scan(directory) {
    const items = fs.readdirSync(directory);

    items.forEach(item => {
      const fullPath = `${directory}/${item}`;

      if (fs.statSync(fullPath).isDirectory()) {
        scan(fullPath);
      } else {
        files.push(fullPath);
      }
    });
  }

  scan(dir);

  return files;
}

/**
 * Gets concatenated content of all Lua files in directory
 * @param {string} dir - Directory to scan
 * @returns {string} Concatenated Lua file contents
 */
function getAllLuaContent(dir) {
  return getAllFiles(dir)
    .filter(file => file.endsWith('.lua'))
    .map(file => fs.readFileSync(file, 'utf8'))
    .join('');
}

// Execute if run directly
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [,, sourceDir, outputFile] = process.argv;

  packageLoveGame(sourceDir, outputFile)
    .catch(err => {
      console.log(
        chalk.red('\nError packaging game:', err)
      );
      process.exit(1);
    });
}

export { packageLoveGame };
