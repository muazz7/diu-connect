import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function POST(request: Request) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded || decoded.role !== 'STUDENT') {
            return NextResponse.json({ error: 'Only students can enroll' }, { status: 403 });
        }

        const body = await request.json();
        const { chatRoomId, chatPassword } = body;

        if (!chatRoomId || !chatPassword) {
            return NextResponse.json({ error: 'Missing Room ID or Password' }, { status: 400 });
        }

        const section = await prisma.section.findUnique({
            where: { chatRoomId }
        });

        if (!section) {
            return NextResponse.json({ error: 'Chat Room not found' }, { status: 404 });
        }

        if (section.chatPassword !== chatPassword) {
            return NextResponse.json({ error: 'Invalid Password' }, { status: 401 });
        }

        const existingEnrollment = await prisma.enrollment.findUnique({
            where: {
                userId_sectionId: {
                    userId: decoded.userId,
                    sectionId: section.id
                }
            }
        });

        if (existingEnrollment) {
            return NextResponse.json({ error: 'Already enrolled' }, { status: 400 });
        }

        const enrollment = await prisma.enrollment.create({
            data: {
                userId: decoded.userId,
                sectionId: section.id
            }
        });

        return NextResponse.json({ message: 'Enrolled successfully', enrollment }, { status: 201 });

    } catch (error) {
        console.error(error);
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}
