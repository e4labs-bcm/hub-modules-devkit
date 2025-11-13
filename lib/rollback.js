#!/usr/bin/env node

/**
 * Sistema de Rollback - Hub Modules DevKit
 *
 * Permite voltar para uma versão anterior específica.
 * Usa git tags para listar versões disponíveis.
 *
 * Filosofia: "Make it right, make it work, make it fast"
 */

const { execSync } = require('child_process');
const chalk = require('chalk');
const inquirer = require('inquirer');

/**
 * Faz rollback para uma versão anterior
 */
async function rollback() {
  try {
    // 1. Obter versão atual
    const currentVersion = require('../package.json').version;
    const currentBranch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf-8' }).trim();

    console.log(chalk.blue(`🕐 Versão atual: v${currentVersion}`));
    console.log(chalk.gray(`   Branch: ${currentBranch}\n`));

    // 2. Listar versões disponíveis (git tags)
    let tagsOutput;
    try {
      tagsOutput = execSync('git tag -l --sort=-v:refname', { encoding: 'utf-8' });
    } catch (error) {
      console.log(chalk.red('❌ Erro ao listar versões.'));
      console.log(chalk.gray('   Certifique-se de que está em um repositório Git com tags.'));
      process.exit(1);
    }

    const tags = tagsOutput.trim().split('\n').filter((tag) => tag.length > 0).slice(0, 10); // Últimas 10

    if (tags.length === 0) {
      console.log(chalk.red('❌ Nenhuma versão anterior encontrada.'));
      console.log(chalk.gray('   Este repositório ainda não possui tags (releases).'));
      return;
    }

    // 3. Obter metadata de cada tag (data e mensagem)
    const choices = tags.map((tag) => {
      try {
        const date = execSync(`git log -1 --format=%ai ${tag}`, { encoding: 'utf-8' }).trim().split(' ')[0];
        const message = execSync(`git tag -l --format="%(contents:subject)" ${tag}`, { encoding: 'utf-8' }).trim() || 'Release';

        return {
          name: `${tag} (${date}) - ${message}`,
          value: tag,
          short: tag,
        };
      } catch (error) {
        return {
          name: `${tag} (data desconhecida)`,
          value: tag,
          short: tag,
        };
      }
    });

    console.log(chalk.cyan('📦 Versões disponíveis:\n'));

    // 4. Perguntar qual versão
    const { selectedVersion } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selectedVersion',
        message: 'Escolha a versão para fazer rollback:',
        choices,
      },
    ]);

    // 5. Aviso sobre detached HEAD
    console.log(chalk.yellow('\n⚠️  ATENÇÃO:'));
    console.log(chalk.gray('   Você será movido para "detached HEAD" (versão fixa).'));
    console.log(chalk.gray('   Para voltar à versão mais recente: git checkout main'));
    console.log(chalk.gray('   Para atualizar novamente: hubapp-devkit update\n'));

    // 6. Confirmação
    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Confirma rollback para ${selectedVersion}?`,
        default: false,
      },
    ]);

    if (!confirm) {
      console.log(chalk.yellow('❌ Rollback cancelado.'));
      return;
    }

    // 7. Verificar mudanças não commitadas
    const statusOutput = execSync('git status --porcelain', { encoding: 'utf-8' });
    if (statusOutput.trim().length > 0) {
      console.log(chalk.yellow('\n⚠️  Você tem mudanças não commitadas:'));
      console.log(statusOutput);

      const { stash } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'stash',
          message: 'Deseja fazer stash das mudanças antes de continuar?',
          default: true,
        },
      ]);

      if (stash) {
        execSync('git stash', { stdio: 'inherit' });
        console.log(chalk.green('✅ Mudanças guardadas em stash.'));
        console.log(chalk.gray('   Para recuperar: git stash pop\n'));
      } else {
        console.log(chalk.red('❌ Rollback cancelado (mudanças não commitadas).'));
        console.log(chalk.gray('   Faça commit ou stash antes de continuar.'));
        return;
      }
    }

    // 8. Executar checkout
    try {
      console.log(chalk.blue('\n⏳ Fazendo rollback...\n'));
      execSync(`git checkout ${selectedVersion}`, { stdio: 'inherit' });

      // Reinstalar dependências (package.json pode ter mudado)
      console.log(chalk.blue('\n📦 Reinstalando dependências...\n'));
      execSync('npm install', { stdio: 'inherit' });

      console.log(chalk.green(`\n✅ Rollback concluído! Você está em ${selectedVersion}\n`));
      console.log(chalk.gray('💡 Para voltar ao latest: hubapp-devkit update'));
      console.log(chalk.gray('💡 Para voltar ao branch main: git checkout main'));
    } catch (error) {
      console.error(chalk.red('\n❌ Erro ao fazer rollback:'), error.message);
      console.log(chalk.yellow('\n🔧 Possíveis soluções:'));
      console.log('  1. Verifique se a tag existe: git tag -l');
      console.log('  2. Tente voltar ao main: git checkout main');
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red('❌ Erro inesperado:'), error.message);
    process.exit(1);
  }
}

module.exports = { rollback };
