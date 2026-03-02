import { NextResponse } from 'next/server';
import prisma from '@/lib/db';
import { verifyToken } from '@/lib/auth';

export async function POST(request: Request) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const token = authHeader.split(' ')[1];
        const decoded = verifyToken(token) as any;
        if (!decoded || decoded.role !== 'TEACHER') {
            return NextResponse.json({ error: 'Only teachers can create sections' }, { status: 403 });
        }

        const body = await request.json();
        const { name, courseId } = body;

        const section = await prisma.section.create({
            data: {
                name,
                courseId
            }
        });

        return NextResponse.json(section, { status: 201 });

    } catch (error) {
        return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
    }
}

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const courseId = searchParams.get('courseId');

    if (!courseId) return NextResponse.json({ error: 'Missing courseId' }, { status: 400 });

    const sections = await prisma.section.findMany({
        where: { courseId }
    });

    return NextResponse.json(sections);
}
