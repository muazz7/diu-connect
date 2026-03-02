import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const sectionId = searchParams.get('sectionId');

    if (!sectionId) return NextResponse.json({ error: 'Missing sectionId' }, { status: 400 });

    const messages = await prisma.message.findMany({
        where: { sectionId },
        include: {
            sender: {
                select: { name: true, id: true }
            }
        },
        orderBy: { createdAt: 'asc' }
    });

    return NextResponse.json(messages);
}

export async function POST(request: Request) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded) return NextResponse.json({ error: 'Invalid token' }, { status: 401 });

        const body = await request.json();
        const { content, sectionId } = body;

        if (decoded.role === 'STUDENT') {
            const lastMessage = await prisma.message.findFirst({
                where: {
                    senderId: decoded.userId,
                    sectionId: sectionId
                },
                orderBy: { createdAt: 'desc' }
            });

            if (lastMessage) {
                const timeDiff = new Date().getTime() - new Date(lastMessage.createdAt).getTime();
                if (timeDiff < 30000) {
                    return NextResponse.json({ error: 'Please wait 30 seconds between messages' }, { status: 429 });
                }
            }
        }

        const message = await prisma.message.create({
            data: {
                content,
                senderId: decoded.userId,
                sectionId
            },
            include: {
                sender: { select: { name: true } }
            }
        });

        return NextResponse.json(message, { status: 201 });

    } catch (error) {
        console.error(error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
