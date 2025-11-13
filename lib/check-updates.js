#!/usr/bin/env node

/**
 * Sistema de Verificação de Atualizações - Hub Modules DevKit
 *
 * Verifica se há novas versões disponíveis no GitHub.
 * Suporta modo silencioso para auto-check em background.
 *
 * Filosofia: "Make it right, make it work, make it fast"
 */

const { Octokit } = require('@octokit/rest');
const semver = require('semver');
const chalk = require('chalk');
const fs = require('fs');
const path = require('path');

/**
 * Verifica se há atualizações disponíveis
 * @param {boolean} silent - Se true, não exibe mensagens (para auto-check)
 * @returns {Promise<boolean>} - true se há atualização disponível
 */
async function checkUpdates(silent = false) {
  const currentVersion = require('../package.json').version;

  try {
    const octokit = new Octokit();
    const { data: release } = await octokit.repos.getLatestRelease({
      owner: 'e4labs-bcm',
      repo: 'hub-modules-devkit',
    });

    const latestVersion = release.tag_name.replace('v', '');

    // Já está na versão mais recente
    if (semver.eq(currentVersion, latestVersion)) {
      if (!silent) {
        console.log(chalk.green('✅ Você já está na versão mais recente!'));
      }
      return false;
    }

    if (!silent) {
      console.log(chalk.cyan('\n📦 Nova versão disponível!\n'));
      console.log(`  Atual:  ${chalk.yellow(`v${currentVersion}`)}`);
      console.log(`  Latest: ${chalk.green(`v${latestVersion}`)}\n`);

      // Determinar tipo de atualização (major, minor, patch)
      const diff = semver.diff(currentVersion, latestVersion);
      const typeLabel = {
        major: chalk.red('MAJOR (Breaking Changes)'),
        minor: chalk.yellow('MINOR (New Features)'),
        patch: chalk.green('PATCH (Bug Fixes)'),
      }[diff] || chalk.gray('UNKNOWN');

      console.log(`  Tipo: ${typeLabel}\n`);

      // Mostrar changelog resumido (primeiras 5 linhas)
      if (release.body) {
        const briefChangelog = release.body
          .split('\n')
          .slice(0, 5)
          .map((line) => `  ${line}`)
          .join('\n');

        console.log('  Changelog:');
        console.log(briefChangelog + '\n');
      }

      console.log(chalk.blue('Para atualizar: hub-devkit update'));
      console.log(chalk.blue('Para mais detalhes: hubapp-devkit check-updates --full'));
      console.log(chalk.gray(`Release notes: ${release.html_url}`));
    }

    return true;
  } catch (error) {
    // Fail silently (offline, rate limit, etc)
    if (!silent) {
      console.log(chalk.gray('⚠️  Não foi possível verificar atualizações'));
      console.log(chalk.gray(`   (Offline ou rate limit do GitHub)`));
    }
    return false;
  }
}

/**
 * Auto-check de atualizações com cache de 24 horas
 * Usado para notificações não invasivas em background
 * @returns {Promise<boolean>} - true se há atualização disponível
 */
async function autoCheckUpdates() {
  const cacheFile = path.join(__dirname, '../.update-check-cache');

  // Verificar cache (só checa 1x por dia)
  if (fs.existsSync(cacheFile)) {
    try {
      const lastCheck = parseInt(fs.readFileSync(cacheFile, 'utf-8'), 10);
      const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;

      if (lastCheck > oneDayAgo) {
        return false; // Já verificou hoje
      }
    } catch (error) {
      // Cache corrompido, ignorar e continuar
    }
  }

  // Verificar atualização (silenciosamente)
  const hasUpdate = await checkUpdates(true);

  // Atualizar cache
  try {
    fs.writeFileSync(cacheFile, Date.now().toString(), 'utf-8');
  } catch (error) {
    // Erro ao escrever cache não é crítico, ignorar
  }

  return hasUpdate;
}

module.exports = { checkUpdates, autoCheckUpdates };
