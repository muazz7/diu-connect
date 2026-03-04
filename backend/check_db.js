const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const sections = await prisma.section.findMany();
    console.log(sections);
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
