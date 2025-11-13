#!/usr/bin/env node

/**
 * Sistema de Atualização - Hub Modules DevKit
 *
 * Atualiza o DevKit para a versão mais recente via git pull.
 * Detecta breaking changes e mostra changelog completo.
 *
 * Filosofia: "Make it right, make it work, make it fast"
 */

const { Octokit } = require('@octokit/rest');
const semver = require('semver');
const chalk = require('chalk');
const inquirer = require('inquirer');
const { execSync } = require('child_process');

/**
 * Atualiza o DevKit para a versão mais recente
 */
async function update() {
  const currentVersion = require('../package.json').version;

  console.log(chalk.blue('🔍 Verificando atualizações...\n'));

  try {
    // 1. Fetch latest release do GitHub
    const octokit = new Octokit();
    const { data: release } = await octokit.repos.getLatestRelease({
      owner: 'e4labs-bcm',
      repo: 'hub-modules-devkit',
    });

    const latestVersion = release.tag_name.replace('v', '');

    // 2. Comparar versões
    if (semver.eq(currentVersion, latestVersion)) {
      console.log(chalk.green('✅ Você já está na versão mais recente!'));
      return;
    }

    console.log(chalk.cyan(`📦 Nova versão disponível: ${chalk.green(`v${latestVersion}`)} (atual: ${chalk.yellow(`v${currentVersion}`)})\n`));

    // 3. Verificar se é breaking change (major version)
    const isBreaking = semver.major(latestVersion) > semver.major(currentVersion);

    if (isBreaking) {
      console.log(chalk.red('⚠️  BREAKING CHANGES detectadas!\n'));
    }

    // 4. Mostrar changelog completo
    console.log(chalk.cyan('Mudanças nesta versão:'));
    console.log(chalk.gray('─'.repeat(60)));
    if (release.body) {
      console.log(release.body);
    } else {
      console.log('  (Nenhuma descrição disponível)');
    }
    console.log(chalk.gray('─'.repeat(60)));
    console.log('');

    // 5. Confirmação do usuário
    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: 'Deseja atualizar?',
        default: true,
      },
    ]);

    if (!confirm) {
      console.log(chalk.yellow('❌ Atualização cancelada.'));
      return;
    }

    // 6. Executar git pull
    try {
      console.log(chalk.blue('\n⏳ Atualizando...\n'));

      // Fetch tags e pull
      execSync('git fetch --tags', { stdio: 'inherit' });
      execSync('git pull origin main', { stdio: 'inherit' });

      // Reinstalar dependências (caso package.json tenha mudado)
      console.log(chalk.blue('\n📦 Reinstalando dependências...\n'));
      execSync('npm install', { stdio: 'inherit' });

      console.log(chalk.green(`\n✅ DevKit atualizado para v${latestVersion}!\n`));
      console.log(chalk.gray('💡 Dica: Se algo quebrar, execute: hubapp-devkit rollback'));
    } catch (error) {
      console.error(chalk.red('\n❌ Erro ao atualizar:'), error.message);
      console.log(chalk.yellow('\n🔧 Possíveis soluções:'));
      console.log('  1. Verifique se há mudanças não commitadas: git status');
      console.log('  2. Faça commit ou stash: git stash');
      console.log('  3. Tente novamente: hubapp-devkit update');
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red('❌ Erro ao verificar atualizações:'), error.message);
    console.log(chalk.gray('\nPossíveis causas:'));
    console.log('  - Sem conexão com internet');
    console.log('  - Rate limit do GitHub API excedido');
    console.log('  - Repositório indisponível');
    process.exit(1);
  }
}

module.exports = { update };
